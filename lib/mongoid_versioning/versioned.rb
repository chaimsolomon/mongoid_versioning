module MongoidVersioning
  module Versioned

    def self.included base
      base.extend ClassMethods
      base.class_eval do
        define_model_callbacks :revise, only: [:before, :after]

        field :_version, type: Integer
        field :_based_on_version, type: Integer

        versions_collection.indexes.create(
          { _orig_id: 1, _version: 1 }, { unique: true }
        )

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
        lt(_version: _version).
        desc(:_version)
    end

    def version v
      return latest_version if v == _version
      previous_versions.where(_version: v).first
    end

    private # =============================================================

    def set_initial_version
      self._version ||= 1
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

        res1 = self.class.versions_collection.where(_orig_id: previous_doc['_orig_id'], _version: previous_doc._version).upsert(previous_doc.as_document)

        self._based_on_version = _version || current_version
        self._version = current_version+1

        res2 = self.class.collection.where(_id: id, _version: current_version).update(self.as_document)

        # replay flow if someone else updated the document before us
        break unless res2['n'] != 1
      end
    end

  end
end