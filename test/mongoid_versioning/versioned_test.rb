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
          before do
            subject.revise
            @current_docs = TestDocument.collection.where({ _id: subject.id })
            @version_docs = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: subject.id)
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
          before do
            subject.name = 'v1'
            subject.revise
            subject.name = 'v2'
            subject.revise
            subject.name = 'v3'
            subject.revise

            @current_docs = TestDocument.collection.where(_id: subject.id)
            @version_docs = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: subject.id)
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

        # ---------------------------------------------------------------------
        
        describe 'revise on previous version' do
          before do
            subject.name = 'v1'
            subject.revise
            subject.name = 'v2'
            subject.revise
            subject.name = 'v3'
            subject.revise

            @new_version = subject.version(1)
            @new_version.revise
          end

          it 'saves reverted attribute' do
            @new_version.name.must_equal 'v1'
          end
          it 'updates :_version' do
            @new_version._version.must_equal 4
          end
          it 'updates :_based_on_version' do
            @new_version._based_on_version.must_equal 1
          end
        end
      end

      # =====================================================================

      describe 'versions' do
        before do
          subject.name = 'v1'
          subject.revise
          subject.name = 'v2'
          subject.revise
          subject.name = 'v3'
          subject.revise
          subject.name = 'Foo'
        end

        it 'returns an Array' do
          subject.versions.must_be_kind_of Array
        end

        # ---------------------------------------------------------------------

        describe '#previous_versions' do
          it 'returns everything but the latest' do
            subject.previous_versions.map(&:_version).must_equal [2,1]
          end
          it 'correctly reverts document _ids' do
            subject.previous_versions.map(&:id).uniq.must_equal [subject.id]
          end
        end

        # ---------------------------------------------------------------------

        describe '#latest_version' do
          it 'includes the latest version as in the database' do
            subject.latest_version.name.wont_equal 'Foo'
          end
        end

        # ---------------------------------------------------------------------

        describe '#versions' do
          it 'returns all versions including the latest one' do
            subject.versions.map(&:_version).must_equal [3,2,1]
          end
        end


        # ---------------------------------------------------------------------

        describe '#version' do
          before do
            subject.name = 'v1'
            subject.revise
            subject.name = 'v2'
            subject.revise
            subject.name = 'v3'
            subject.revise
            subject.name = 'Foo'
          end

          describe 'when latest version' do
            it 'returns the version from db' do
              subject.version(3)._version.must_equal 3
            end
          end

          describe 'when previous version' do
            it 'returns the version from db' do
              subject.version(1)._version.must_equal 1
            end
          end

          describe 'when version does not exist' do
            it 'returns nil' do
              subject.version(10).must_be_nil
            end
          end
        end
      end
    end

  end
end
