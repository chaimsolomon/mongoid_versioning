require "mongoid_versioning/version"

module MongoidVersioning

  extend ActiveSupport::Concern

  module ClassMethods
    def versioned_collection_name
      [collection.name, 'versions'].join('.')
    end
  end

end