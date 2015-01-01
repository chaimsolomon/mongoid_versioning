require 'test_helper'

class TestDocument
  include Mongoid::Document
  include MongoidVersioning::Versioned

  attr_accessor :callbacks

  field :name, type: String

  validates :name, presence: true

  before_revise -> i { i.callbacks = i.callbacks << 'before_revise' }
  after_revise -> i { i.callbacks = i.callbacks << 'after_revise' }
  before_save -> i { i.callbacks = i.callbacks << 'before_save' }
  after_save -> i { i.callbacks = i.callbacks << 'after_save' }
  before_update -> i { i.callbacks = i.callbacks << 'before_update' }
  after_update -> i { i.callbacks = i.callbacks << 'after_update' }
  before_create -> i { i.callbacks = i.callbacks << 'before_create' }
  after_create -> i { i.callbacks = i.callbacks << 'after_create' }

  def callbacks
    @callbacks ||= []
  end
end

module MongoidVersioning
  describe Versioned do

    subject { TestDocument.new(name: 'Init') }

    # =====================================================================

    describe 'fields' do
      describe '_version' do
        it { subject.must_respond_to :_version }
        it { subject._version.must_be_nil }

        describe 'on create' do
          before { subject.save }
          it { subject._version.must_equal 1 }
        end
      end

      describe '_based_on_version' do
        it { subject.must_respond_to :_based_on_version }
        it { subject._based_on_version.must_be_nil }
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

        describe 'on new document' do
          let(:new_document) { TestDocument.new(name: 'New') }

          before do
            new_document.name = 'Foo'
            new_document.revise

            @versions = TestDocument.versions_collection.where(_orig_id: new_document.id).sort(_version: -1)
            @current = TestDocument.collection.where(_id: new_document.id).first
          end

          it 'sets _version' do
            new_document._version.must_equal 1
          end
          it 'sets _based_on_version' do
            new_document._based_on_version.must_be_nil
          end

          describe 'when invalid' do
            before { new_document.name = nil }

            it 'returns false' do
              new_document.revise.must_equal false
            end
          end

          describe 'callbacks' do
            it 'does not run :revise' do
              new_document.callbacks.wont_include 'before_revise'
              new_document.callbacks.wont_include 'after_revise'
            end
          end

          describe 'versions' do
            it 'does not store anything' do
              @versions.count.must_equal 0
            end
          end

          describe 'current' do
            it 'stores updated doc into current collection' do
              @current["_version"].must_equal 1
              @current["_based_on_version"].must_be_nil
              @current["name"].must_equal 'Foo'
            end
          end
        end

        # ---------------------------------------------------------------------

        describe 'on existing document' do
          let(:existing_document) { TestDocument.create(name: 'Existing') }

          before do
            existing_document.callbacks = []
            existing_document.name = 'Foo'
            existing_document.revise

            @versions = TestDocument.versions_collection.where(_orig_id: existing_document.id).sort(_version: -1)
            @current = TestDocument.collection.where(_id: existing_document.id).first
          end

          it 'sets _version' do
            existing_document._version.must_equal 2
          end
          it 'sets _based_on_version' do
            existing_document._based_on_version.must_equal 1
          end

          describe 'when invalid' do
            before { existing_document.name = nil }

            it 'returns false' do
              existing_document.revise.must_equal false
            end
          end

          describe 'callbacks' do
            it 'runs :revise, :save, :create' do
              existing_document.callbacks.must_equal %w(before_revise before_save before_update after_update after_save after_revise)
            end
          end

          describe 'versions' do
            it 'stores previous doc' do
              @versions.count.must_equal 1
              @versions.first["_version"].must_equal 1
              @versions.first["_based_on_version"].must_be_nil
              @versions.first["name"].must_equal 'Existing'
            end
          end

          describe 'current' do
            it 'stores updated doc into current collection' do
              @current["_version"].must_equal 2
              @current["_based_on_version"].must_equal 1
              @current["name"].must_equal 'Foo'
            end
          end

          describe 'subsequent revise' do
            before do
              existing_document.callbacks = []
              existing_document.name = 'Bar'
              existing_document.revise

              @versions = TestDocument.versions_collection.where(_orig_id: existing_document.id).sort(_version: -1)
              @current = TestDocument.collection.where(_id: existing_document.id).first
            end

            it 'sets _version' do
              existing_document._version.must_equal 3
            end
            it 'sets _based_on_version' do
              existing_document._based_on_version.must_equal 2
            end

            describe 'versions' do
              it 'stores previous doc' do
                @versions.count.must_equal 2
                @versions.map{ |v| v['_version'] }.must_equal [2, 1]
                @versions.map{ |v| v['_based_on_version'] }.must_equal [1, nil]
                @versions.first["_version"].must_equal 2
                @versions.first["_based_on_version"].must_equal 1
                @versions.first["name"].must_equal 'Foo'
              end
            end

            describe 'current' do
              it 'stores updated doc into current collection' do
                @current["_version"].must_equal 3
                @current["_based_on_version"].must_equal 2
                @current["name"].must_equal 'Bar'
              end
            end
          end
        end

        # ---------------------------------------------------------------------

        describe 'on concurrent updates' do
        end

        # ---------------------------------------------------------------------

        # describe 'subsequent revision' do
        #   before do
        #     subject.name = 'v1'
        #     subject.revise
        #     subject.name = 'v2'
        #     subject.revise
        #     subject.name = 'v3'
        #     subject.revise

        #     @current_docs = TestDocument.collection.where(_id: subject.id)
        #     @version_docs = TestDocument.collection.database[TestDocument.versions_collection_name].where(_orig_id: subject.id)
        #   end

        #   describe 'default collection' do
        #     it 'updates the current document in the db' do
        #       @current_docs.first['name'].must_equal 'v3'
        #       @current_docs.first['_version'].must_equal 3
        #       @current_docs.first['_based_on_version'].must_equal 2
        #       @current_docs.count.must_equal 1
        #     end
        #   end

        #   describe 'versions' do
        #     it 'has 2 previous versions' do
        #       @version_docs.count.must_equal 2
        #       @version_docs.collect{ |i| i['_version'] }.must_equal [1,2]
        #       @version_docs.collect{ |i| i['_based_on_version'] }.must_equal [nil,1]
        #     end
        #   end
        # end

        # ---------------------------------------------------------------------

        # describe 'revise on previous version' do
        #   before do
        #     subject.name = 'v1'
        #     subject.revise
        #     subject.name = 'v2'
        #     subject.revise
        #     subject.name = 'v3'
        #     subject.revise

        #     @new_version = subject.version(1)
        #     @new_version.revise
        #   end

        #   it 'saves reverted attribute' do
        #     @new_version.name.must_equal 'v1'
        #   end
        #   it 'updates :_version' do
        #     @new_version._version.must_equal 4
        #   end
        #   it 'updates :_based_on_version' do
        #     @new_version._based_on_version.must_equal 1
        #   end
        # end
      end

      # =====================================================================

      # describe 'versions' do
      #   before do
      #     subject.name = 'v1'
      #     subject.revise
      #     subject.name = 'v2'
      #     subject.revise
      #     subject.name = 'v3'
      #     subject.revise
      #     subject.name = 'Foo'
      #   end

      #   # it 'returns an Array' do
      #   #   subject.versions.must_be_kind_of Array
      #   # end

      #   # ---------------------------------------------------------------------

      #   describe '#previous_versions' do
      #     # it 'returns everything but the latest' do
      #     #   subject.previous_versions.map(&:_version).must_equal [2,1]
      #     # end
      #     # it 'reverts document _ids' do
      #     #   subject.previous_versions.map(&:id).uniq.must_equal [subject.id]
      #     # end
      #   end

      #   describe '#latest_version' do
      #     # it 'includes the latest version as in the database' do
      #     #   subject.latest_version.name.wont_equal 'Foo'
      #     # end
      #   end

      #   describe '#versions' do
      #     # it 'returns all versions including the latest one' do
      #     #   subject.versions.map(&:_version).must_equal [3,2,1]
      #     # end
      #   end


      #   # ---------------------------------------------------------------------

      #   describe '#version' do
      #     # before do
      #     #   subject.name = 'v1'
      #     #   subject.revise
      #     #   subject.name = 'v2'
      #     #   subject.revise
      #     #   subject.name = 'v3'
      #     #   subject.revise
      #     #   subject.name = 'Foo'
      #     # end

      #     # describe 'when latest version' do
      #     #   it 'returns the version from db' do
      #     #     subject.version(3)._version.must_equal 3
      #     #   end
      #     # end

      #     # describe 'when previous version' do
      #     #   it 'returns the version from db' do
      #     #     subject.version(1)._version.must_equal 1
      #     #   end
      #     # end

      #     # describe 'when version does not exist' do
      #     #   it 'returns nil' do
      #     #     subject.version(10).must_be_nil
      #     #   end
      #     # end
      #   end
      # end

    end

  end
end
