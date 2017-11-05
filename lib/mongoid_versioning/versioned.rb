module MongoidVersioning
  module Versioned

    def self.included base
      base.extend ClassMethods
      base.class_eval do
        define_model_callbacks :revise, only: [:before, :after]

        field :_version, type: Integer
        field :_based_on_version, type: Integer

        versions_collection.indexes.create_one(
          { _orig_id: 1, _version: 1 }, { unique: true }
        )

        class_attribute :version_max
        class_attribute :version_min_hold_time

        before_create :set_initial_version
        after_initialize :revert_id
      end
    end

    # =====================================================================

    module ClassMethods
      def versions_collection_name
        [collection.name, 'versions'].join('.')
      end

      def versions_collection
        collection.database[versions_collection_name]
      end

      def max_versions(number)
        self.version_max = number.to_i
      end

      def min_version_hold_time(days)
        self.version_min_hold_time = days.to_i
      end
    end

    # =====================================================================

    def revise options={}
      return save if new_record?

      return false if performing_validations?(options) && invalid?(:update)
      process_flagged_destroys
      result = run_callbacks(:revise) do
        run_callbacks(:save) do
          run_callbacks(:update) do
            _revise
            true
          end
        end
      end
      post_process_persist(result, options) and self
    end

    def revise! options={}
      unless revise(options)
        fail_due_to_validation! unless errors.empty?
        fail_due_to_callback!(:revise!)
      end
      true
    end

    # ---------------------------------------------------------------------

    def versions
      [latest_version].concat(previous_versions)
    end

    def latest_version
      self.class.where(_id: id).first
    end

    def previous_versions
      self.class.with(collection: self.class.versions_collection_name).
        where(_orig_id: id).
        ne(_version: latest_version._version).
        desc(:_version)
    end

    def version v
      return latest_version if v == _version
      previous_versions.where(_version: v).first
    end

    private # =============================================================

    def set_initial_version
      self[:_version] ||= 1
    end

    def revert_id
      return unless self['_orig_id']
      self._id = self['_orig_id']
    end

    def _revise
      loop do
        previous_doc = latest_version

        previous_doc['_orig_id'] = previous_doc['_id']
        previous_doc['_id'] = BSON::ObjectId.new

        current_version = previous_doc._version

        res1 = self.class.versions_collection.find(_orig_id: previous_doc['_orig_id'], _version: previous_doc._version)
        previous_doc[:_version] = current_version if previous_doc[:_version].nil?
        self.class.versions_collection.insert_one(previous_doc.as_document) if res1.count == 0

        self._based_on_version = _version || current_version
        self._version = current_version+1

        res2 = self.class.collection.find(_id: id, _version: current_version).update_one(self.as_document)

        # replay flow if someone else updated the document before us
        break unless res2.n != 1
      end
      if version_max.present? && versions.length > version_max
        if version_min_hold_time.present?
          d = DateTime.current - version_min_hold_time
          versions_to_be_deleted = versions.sort_by {|x| x[:_version]}.reverse[version_max..-1].select do |x|
            x[:updated_at] < d
          end.collect do |x|
            {_orig_id: x[:_orig_id], _version: x[:_version]}
          end
          versions_to_be_deleted.each do |v|
            self.class.versions_collection.find(v).delete_one
          end
        end
      end
    end
  end
end