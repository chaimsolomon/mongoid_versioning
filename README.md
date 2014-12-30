# Mongoid Versioning

[![Build Status](https://travis-ci.org/tomasc/mongoid_versioning.svg)](https://travis-ci.org/tomasc/mongoid_versioning) [![Gem Version](https://badge.fury.io/rb/mongoid_versioning.svg)](http://badge.fury.io/rb/mongoid_versioning) [![Coverage Status](https://img.shields.io/coveralls/tomasc/mongoid_versioning.svg)](https://coveralls.io/r/tomasc/mongoid_versioning)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongoid_versioning'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install mongoid_versioning
```

## Usage

Include the `MongoidVersioning::Versioned` module into your model:

```ruby
class MyVersionedDocument
    include Mongoid::Document
    include MongoidVersioning::Versioned
end
```

Your class will then have:

```ruby
field :_version, type: Integer
field :_based_on_version, type: Integer
```

To create new version of your document:

```ruby
doc = MyVersionedDocument.new
doc.revise # => true
doc._version # => 1
doc._based_on_version # => nil
```

To access all previous versions:

```ruby
doc.previous_versions # => Mongoid::Criteria
```

These versions are stored in separate collection, by default named by appending `.versions` to name of the source collection. In the above example it is `my_versioned_documents.versions`.

To access latest version (as stored in the db):

```ruby
doc.latest_version # => MyVersionedDocument
```

To get all versions of a document:

```ruby
doc.versions # => Array
```

## Further Reading

See [Further Thoughts on How to Track Versions with MongoDB](http://askasya.com/post/revisitversions).

## Contributing

1. Fork it ( https://github.com/tomasc/mongoid_versioning/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
