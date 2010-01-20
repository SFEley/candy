require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "candy"
    gem.summary = %Q{The simplest MongoDB ORM}
    gem.description = <<DESCRIPTION
Candy is a lightweight ORM for the MongoDB database. If MongoMapper is Rails, Candy is Sinatra. 
It provides a module you mix into any class, enabling the class to connect to Mongo on its own
and push its objects into a collection. Candied objects act like OpenStructs, allowing attributes
to be defined and updated in Mongo immediately without having to be declared in the class. 
Mongo's atomic operators are used whenever possible, and a smart serializer (Candy::Wrapper) 
converts almost any object for assignment to any attribute.
DESCRIPTION

    gem.email = "sfeley@gmail.com"
    gem.homepage = "http://github.com/SFEley/candy"
    gem.authors = ["Stephen Eley"]
    gem.add_dependency "mongo", ">= 0.18"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    gem.add_development_dependency "mocha", ">= 0.9.8"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
