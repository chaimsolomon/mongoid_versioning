# require 'test_helper'

# class Document
#   include Mongoid::Document
#   include MongoidVersioning
# end

# module MongoidVersioning
#   describe 'Document' do

#     subject { Document.new }
    
#     # =====================================================================
    
#     describe '.versions_collection_name' do
#       it 'infers name for version collection' do
#         Document.versions_collection_name.must_equal "#{Document.collection.name}.versions"
#       end
#     end

#     describe '.versions' do
#       it 'returns previous versions from the versions collection'
#       it 'returns current version as saved in the standard collection'
#     end

#     # =====================================================================

#     describe '#_version' do
#       it 'has :_version field' do
#         subject.must_respond_to :_version
#       end

#       it 'is nil by default' do
#         subject._version.must_be_nil
#       end
#     end
    
#     # ---------------------------------------------------------------------
    
#     describe '#revise' do
#       it 'triggers :save'

#       describe 'when save successful' do
#         it 'udpates the version number'
#         it 'creates new version in the versions collection'
#       end

#       describe 'when not valid?' do
#       end
#     end

#     # ---------------------------------------------------------------------
    
#     describe '#revert_to' do
#       describe 'when version exists' do
#         it 'returns it'
#       end

#       describe 'when version does not exist' do
#         it 'raises an error'
#       end
#     end

#     # ---------------------------------------------------------------------
    
#     # describe 'on create' do
#     #   before { subject.save! }

#     #   it 'creates initial version'
#     # end

#   end
# end