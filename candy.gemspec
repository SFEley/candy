# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "candy/version"

Gem::Specification.new do |s|
  s.name = %q{candy}
  s.version = Candy::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors = ["Stephen Eley"]
  s.description = %q{Candy provides simple, transparent object persistence for the MongoDB database.  Classes that 
include Candy modules save all properties to Mongo automatically, can be recursively embedded,
and can retrieve records with chainable open-ended class methods, eliminating the need for 
method calls like 'save' and 'find.'
}
  s.email = %q{sfeley@gmail.com}
  s.homepage = %q{http://github.com/SFEley/candy}
  s.require_paths = ["lib"]
  s.summary = %q{Transparent persistence for MongoDB}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency 'mongo', '~> 1.4.0'
  s.add_dependency 'bson_ext', '~> 1.4.0'

  s.add_development_dependency 'rspec', '~> 2.7.0'
  s.add_development_dependency 'mocha', '~> 0.10.0'
end
