require 'test_helper'

class Document
  include Mongoid::Document
  include MongoidVersioning
end

module MongoidVersioning
  describe 'Document' do
    
    describe '.versioned_collection_name' do
      it 'infers name for version collection' do
        Document.versioned_collection_name.must_equal 'documents.versions'
      end
    end

  end
end