# Mongoid Versioning

[![Build Status](https://travis-ci.org/tomasc/mongoid_versioning.svg)](https://travis-ci.org/tomasc/mongoid_versioning) [![Gem Version](https://badge.fury.io/rb/mongoid_versioning.svg)](http://badge.fury.io/rb/mongoid_versioning) [![Coverage Status](https://img.shields.io/coveralls/tomasc/mongoid_versioning.svg)](https://coveralls.io/r/tomasc/mongoid_versioning)

Placing a document under version control is very unintrusive. Mongoid Versioning only adds a version number property (a field of type `Integer` called `_version`) to the document. It does not touch any other fields. In particular, it also does not place any requirements on the contents of the `_id` field.

Older revisions are stored in a separate collection that shadows the original collection. They are Mongoid documents themselves, and can be queried.

## Installation

Add this line to your application's Gemfile:

```Ruby
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

TODO

## Further Reading

See [How to Track Versions with MongoDB](http://askasya.com/post/trackversions), [Further Thoughts on How to Track Versions with MongoDB](http://askasya.com/post/revisitversions) and [Vermongo: Simple Document Versioning with MongoDB](https://github.com/thiloplanz/v7files/wiki/Vermongo).

## Contributing

1. Fork it ( https://github.com/tomasc/mongoid_versioning/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
