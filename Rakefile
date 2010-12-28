require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "candy"
    gem.summary = %Q{Transparent persistence for MongoDB}
    gem.description = <<DESCRIPTION
Candy provides simple, transparent object persistence for the MongoDB database.  Classes that 
include Candy modules save all properties to Mongo automatically, can be recursively embedded,
and can retrieve records with chainable open-ended class methods, eliminating the need for 
method calls like 'save' and 'find.'
DESCRIPTION

    gem.email = "sfeley@gmail.com"
    gem.homepage = "http://github.com/SFEley/candy"
    gem.authors = ["Stephen Eley"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec')
RSpec::Core::RakeTask.new('rcov') do |spec|
  spec.rcov = true
  spec.rcov_opts = %w[--exclude spec]
end

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
