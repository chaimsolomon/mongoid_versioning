module MongoidVersioning
  module Versioned

    def self.included base
      base.extend ClassMethods
      base.class_eval do
        define_model_callbacks :revise, only: [:before, :after]

        field :_version, type: Integer
        field :_based_on_version, type: Integer

        collection.database[versions_collection_name].indexes.create(
          { _orig_id: 1, _version: 1 }, { unique: true }
        )

        after_initialize :revert_id
      end
    end

    # =====================================================================

    module ClassMethods
      def versions_collection_name
        [collection.name, 'versions'].join('.')
      end
    end

    # =====================================================================

    def revise options={}
      if new_record?
        !_create_revised(options).new_record?
      else
        _update_revised(options)
      end
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

    def revert_id
      return unless self['_orig_id']
      self._id = self['_orig_id']
    end

    # these mirror the #create and #save methods from Mongoid
    def _create_revised options={}
      return self if performing_validations?(options) && invalid?(:create)
      result = run_callbacks(:revise) do
        run_callbacks(:save) do
          run_callbacks(:create) do
            _revise
            true
          end
        end
      end
      post_process_persist(result, options) and self
    end

    def _update_revised options={}
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

    def _revise
      previous_version = nil

      # 1. get the latest version as stored in the db
      if previous_doc = self.class.collection.find({ _id: id }).first

        previous_version = previous_doc["_version"] || 1

        previous_doc['_orig_id'] = previous_doc['_id']
        previous_doc['_id'] = BSON::ObjectId.new
        previous_doc['_version'] = previous_version

        # 2. upsert the latest version into the .versions collection
        self.class.collection.database[self.class.versions_collection_name].where(_orig_id: id, _version: previous_version).upsert(previous_doc)
      end

      # 3. insert new version
      self._based_on_version = _version || previous_version
      self._version = previous_version.to_i+1

      self.class.collection.where(_id: id).upsert(self.as_document)

      # TODO
      # if (result.nModified != 1) {
      #    print("Someone got there first, replay flow to try again");
      # }
    end
  end
end
