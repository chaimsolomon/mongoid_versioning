require 'test_helper'

class Document
  include Mongoid::Document
  include MongoidVersioning

  embeds_many :embedded_documents
end

class EmbeddedDocument
  include Mongoid::Document
  include MongoidVersioning

  embedded_in :document
end

module MongoidVersioning
  describe 'Embedded Document' do
    
    describe '.versioned_collection_name' do
      it 'infers name for version collection' do
        EmbeddedDocument.versioned_collection_name.must_equal "#{EmbeddedDocument.collection.name}.versions"
      end
    end

  end
end