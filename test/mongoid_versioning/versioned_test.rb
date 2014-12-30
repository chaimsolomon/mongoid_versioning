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
      describe '.versions_collection_name' do
        it 'infers name for version collection' do
          subject.class.versions_collection_name.must_equal "#{subject.collection.name}.versions"
        end
      end
    end

    # =====================================================================

    describe 'instance methods' do
      describe '#revise' do

        it 'runs callbacks'
        it 'return false if invalid'

        describe 'new record' do
          let(:new_document) { TestDocument.new }

          before do
            new_document.revise
            @current_docs = TestDocument.collection.where({ _id: new_document.id })
            @version_docs = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: new_document.id)
          end

          describe 'default collection' do
            it 'stores the document' do
              @current_docs.first.must_be :present?
            end
            it '_version to 1' do
              @current_docs.first['_version'].must_equal 1
            end
            it '_based_on_version at nil' do
              @current_docs.first['_based_on_version'].must_be_nil
            end
            it 'maintains only one current doc' do
              @current_docs.count.must_equal 1
            end
          end

          describe 'versions' do
            it 'does not create any versions' do
              @version_docs.count.must_equal 0
            end
          end
        end

        # ---------------------------------------------------------------------

        describe 'existing record' do
          let(:existing_document) { TestDocument.create }

          before do
            existing_document.name = 'Foo'
            existing_document.revise

            @current_docs = TestDocument.collection.where(_id: existing_document.id)
            @version_docs = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: existing_document.id)
          end

          describe 'default collection' do
            it 'updates the document' do
              @current_docs.first['name'].must_equal 'Foo'
            end
            it '_version to 1' do
              @current_docs.first['_version'].must_equal 2
            end
            it 'sets the _based_on_version to nil' do
              @current_docs.first['_based_on_version'].must_equal 1
            end
            it 'maintains only one current doc' do
              @current_docs.count.must_equal 1
            end
          end

          describe 'versions' do
            it 'copies the latest version to .versions' do
              @version_docs.first.must_be :present?
            end

            it '_version to 1' do
              @version_docs.first['_version'].must_equal 1
            end
            it 'creates only one version' do
              @version_docs.count.must_equal 1
            end
          end
        end

        # ---------------------------------------------------------------------

        describe 'subsequent revision' do
          let(:revised_document) { TestDocument.new }

          before do
            revised_document.name = 'v1'
            revised_document.revise
            revised_document.name = 'v2'
            revised_document.revise
            revised_document.name = 'v3'
            revised_document.revise

            @current_docs = TestDocument.collection.where(_id: revised_document.id)
            @version_docs = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: revised_document.id)
          end

          describe 'default collection' do
            it 'updates the current document in the db' do
              @current_docs.first['name'].must_equal 'v3'
              @current_docs.first['_version'].must_equal 3
              @current_docs.first['_based_on_version'].must_equal 2
              @current_docs.count.must_equal 1
            end
          end

          describe 'versions' do
            it 'has 2 previous versions' do
              @version_docs.count.must_equal 2
              @version_docs.collect{ |i| i['_version'] }.must_equal [1,2]
              @version_docs.collect{ |i| i['_based_on_version'] }.must_equal [nil,1]
            end
          end
        end
      end

      # =====================================================================

      describe 'versions' do
        let(:document_with_versions) { TestDocument.new }

        before do
          document_with_versions.name = 'v1'
          document_with_versions.revise
          document_with_versions.name = 'v2'
          document_with_versions.revise
          document_with_versions.name = 'v3'
          document_with_versions.revise
          document_with_versions.name = 'Foo'
        end

        it 'returns an Array' do
          document_with_versions.versions.must_be_kind_of Array
        end

        describe '#previous_versions' do
          it 'returns everything but the latest' do
            document_with_versions.previous_versions.map(&:_version).must_equal [2,1]
          end
          it 'correctly reverts document _ids' do
            document_with_versions.versions.map(&:id).uniq.must_equal [document_with_versions.id]
          end
        end

        describe '#previous_versions' do
          it 'includes the latest version as in the database' do
            document_with_versions.versions.map(&:name).wont_include 'Foo'
          end
        end

        describe '#versions' do
          it 'returns all versions including the latest one' do
            document_with_versions.versions.map(&:_version).must_equal [3,2,1]
          end
        end
      end
    end

  end
end
