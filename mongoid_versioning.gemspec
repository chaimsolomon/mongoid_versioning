# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid_versioning/version'

Gem::Specification.new do |spec|
  spec.name          = "mongoid_versioning"
  spec.version       = MongoidVersioning::VERSION
  spec.authors       = ["Tomas Celizna"]
  spec.email         = ["tomas.celizna@gmail.com"]
  spec.description   = %q{Versioning Mongoid documents by means of separate collection.}
  spec.summary       = %q{Versioning Mongoid documents by means of separate collection.}
  spec.homepage      = "https://github.com/tomasc/mongoid_versioning"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid", "~> 5.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
end
