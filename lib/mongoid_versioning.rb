# http://askasya.com/post/revisitversions

require "mongoid_versioning/version"

require "mongoid_versioning/versioned"

# module MongoidVersioning

#   extend ActiveSupport::Concern

#   # =====================================================================
  
#   included do
#     field :_docId, type: BSON::ObjectId
#     field :_version, type: Integer

#     before_create :create_initial_version

#     self.mongo_session[versions_collection_name].indexes.create(
#       { _docId: 1, _version: 1 }, { unique: true }
#     )
#   end

#   # =====================================================================
  
#   module ClassMethods
#     def versions_collection_name
#       [collection.name, 'versions'].join('.')
#     end

#     def versions
#       self.with(collection: versions_collection_name)
#     end
#   end

#   # =====================================================================
  
#   def revise
    
#   end

#   private # =============================================================
  
#   def create_version
#     # var previous = db.curr_coll.findOne({"docId": 174}, {_id: 0});
#     # var currVersion = previous.v;
#     # var result = db.prev_coll.update(
#     #      {"docId" : previous.docId, "v": previous.v },
#     #      { "$set": previous }
#     #    , {"upsert": true});
#     # 
#     # var current = {"v": currVersion+1, "attr1": previous.attr1, "attr2":"YYYY"};
#     # var result = db.curr_coll.update({"docId": 174, "v": currVersion},
#     #      {"$set": current}
#     # );
#   end

#   def create_initial_version
#     # 
#     # self.with(collection: self.class.versions_collection_name)
#   end

# end