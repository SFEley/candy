# Make me one with everything...
Dir[File.join(File.dirname(__FILE__), 'candy', '*.rb')].each {|f| require f}

require 'candy/exceptions'
require 'candy/crunch'
require 'candy/wrapper'
require 'candy/piece'
require 'candy/collection'

# Mix me into your classes and Mongo will like them!
module Candy
  
  module ClassMethods
    include Crunch::ClassMethods
    
    attr_reader :stamp_create, :stamp_update
    
    # Retrieves an object from Mongo by its ID and returns it.  Returns nil if the ID isn't found in Mongo.
    def find(id)
      if collection.find_one(id)
      end
    end
    
    
    # Retrieves all objects matching the search attributes as an Enumerator (even if it's an empty one).
    # The option fields from Mongo::Collection#find can be passed as well, and will be extracted from the 
    # condition set if they're found.
    def all(conditions={})
      options = extract_options(conditions)
      cursor = collection.find(conditions, options)
      Enumerator.new do |yielder|
        while record = cursor.next_document do
          yielder.yield find(record["_id"])
        end
      end  
    end
    
    # Configures objects to set `created_at` and `updated_at` properties at the appropriate times.
    # Pass `:create` or `:update` to limit it to just one or the other.  Defaults to both.
    def timestamp(*args)
      args = [:create, :update] if args.empty?
      @stamp_create = args.include?(:create)
      @stamp_update = args.include?(:update)
    end
    
    
  private
    # Returns a hash of options matching those enabled in Mongo::Collection#find, if any of them exist
    # in the set of search conditions.
    def extract_options(conditions)
      options = {:fields => []}
      [:fields, :skip, :limit, :sort, :hint, :snapshot, :timeout].each do |option|
        options[option] = conditions.delete(option) if conditions[option]
      end
      options
    end
    
  end
  
  
  
  def self.included(receiver)
    receiver.extend         ClassMethods
  end
  

end