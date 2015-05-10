module MongoidVersioning
  module Versioned

    module Revert
      def restore
        cls = self.class.to_s.split('::').first # Turns User::Version into User.
        document = self.class.const_get(cls).find(self.original_id)
        document.assign_attributes( attributes.except("_id", "original_id") )
        document
      end
    end

    # ---------------------------------------------------------------------
    
    def self.included base
      base.extend ClassMethods
      base.class_eval do
        define_model_callbacks :revise, only: [:before, :after]

        field :_version, type: Integer
        field :_based_on_version, type: Integer

        self.const_set("Version", Class.new)
        self.const_get("Version").class_eval do
          include Mongoid::Document
          include Mongoid::Attributes::Dynamic
          include MongoidVersioning::Versioned::Revert
          field :original_id, type: String
          field :_version, type: Integer
          field :_based_on_version, type: Integer
        end

        before_create :set_initial_version
        after_initialize :revert_id
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
      # self.class.with(collection: self.class.versions_collection_name).
      self.class.const_get("Version").
        where(original_id: id).
        ne(_version: latest_version._version).
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
      return unless self['original_id']
      self._id = self['original_id']
    end

    def _revise
      loop do
        previous_doc = latest_version

        # previous_doc['original_id'] = previous_doc.id
        # previous_doc.id = BSON::ObjectId.new

        current_version = previous_doc._version

        self.class.const_get("Version").create(previous_doc.attributes.except('_id')) do |doc|
          doc.original_id = previous_doc.id
          doc._version = previous_doc._version
        end

        # res1 = self.class.const_get("Version").collection.
        #   where(original_id: previous_doc['original_id'], _version: previous_doc._version).
        #   upsert(previous_doc.as_document)

        # res1 = self.class.versions_collection.where(original_id: previous_doc['original_id'], _version: previous_doc._version).upsert(previous_doc.as_document)

        self._based_on_version = _version || current_version
        self._version = current_version+1

        res2 = self.class.collection.where(_id: id, _version: current_version).update(self.as_document)

        # replay flow if someone else updated the document before us
        break unless res2['n'] != 1
      end
    end

  end
end