module MongoidVersioning
  module Versioned

    def self.included base
      base.extend ClassMethods
      base.class_eval do
        attr_accessor :_is_temporary

        field :_version, type: Integer
        field :_based_on_version, type: Integer
      end
    end

    # =====================================================================

    module ClassMethods
      # def temp_collection_name
      #   [collection.name, 'temp'].join('.')
      # end

      def versions_collection_name
        [collection.name, 'versions'].join('.')
      end
    end

    # =====================================================================

    def revise
      # need to run validations
      # need to run callbacks

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
      self._version = previous_version.to_i+1
      self._based_on_version = previous_version

      self.class.collection.where(_id: id).upsert(self.as_document)

      # if (result.nModified != 1) {
      #    print("Someone got there first, replay flow to try again");
      # }
    end

    def revert_to version
      
    end

  end
end
