require 'test_helper'

class TestDocument
  include Mongoid::Document
  include MongoidVersioning::Versioned

  field :name, type: String
end

module MongoidVersioning
  describe Versioned do

    subject { TestDocument.new }

    # =====================================================================

    describe 'accessors' do
    end

    # =====================================================================
    
    describe 'fields' do
      it 'has :_version' do
        subject.must_respond_to :_version
      end

      it 'has :_based_on_version' do
        subject.must_respond_to :_based_on_version
      end
    end

    # =====================================================================

    describe 'class methods' do
      # describe '.temp_collection_name' do
      #   it 'infers name for tepmorary collection' do
      #     subject.class.temp_collection_name.must_equal "#{subject.collection.name}.temp"
      #   end
      # end

      describe '.versions_collection_name' do
        it 'infers name for version collection' do
          subject.class.versions_collection_name.must_equal "#{subject.collection.name}.versions"
        end
      end
    end

    # =====================================================================

    describe 'instance methods' do
      describe '#revise' do
        describe 'new record' do
          let(:new_document) { TestDocument.new }

          before do
            new_document.revise
            @current_doc = TestDocument.collection.where({ _id: new_document.id }).first
            @version_doc = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: new_document.id).first
          end

          describe 'default collection' do
            it 'stores the document' do
              @current_doc.must_be :present?
            end
            it '_version to 1' do
              @current_doc['_version'].must_equal 1
            end
            it '_based_on_version at nil' do
              @current_doc['_based_on_version'].must_be_nil
            end
          end

          describe 'versions' do
            it 'does not create any versions' do 
              @version_doc.wont_be :present?
            end
          end
        end

        describe 'existing record' do
          let(:existing_document) { TestDocument.create }

          before do
            existing_document.name = 'Foo'
            existing_document.revise

            @current_doc = TestDocument.collection.where(_id: existing_document.id).first
            @version_doc = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: existing_document.id).first
          end

          describe 'default collection' do
            it 'updates the document' do
              @current_doc['name'].must_equal 'Foo'
            end
            it '_version to 1' do
              @current_doc['_version'].must_equal 2
            end
            it 'sets the _based_on_version to nil' do
              @current_doc['_based_on_version'].must_equal 1
            end
          end

          describe 'versions' do
            it 'copies the latest version to .versions' do
              @version_doc.must_be :present?
            end

            it '_version to 1' do
              @version_doc['_version'].must_equal 1
            end
          end
        end

        describe 'subsequent revision' do
          let(:revised_document) { TestDocument.new }

          before do
            revised_document.name = 'v1'
            revised_document.revise
            revised_document.name = 'v2'
            revised_document.revise
            revised_document.name = 'v3'
            revised_document.revise

            @current_doc = TestDocument.collection.where(_id: revised_document.id).first
          end

          it 'updates the current document in the db' do
            @current_doc['name'].must_equal 'v3'
            @current_doc['_version'].must_equal 3
            @current_doc['_based_on_version'].must_equal 2
          end
        end
      end

      describe '#revert_to' do
      end
    end

  end
end