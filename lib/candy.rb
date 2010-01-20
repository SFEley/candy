require 'candy/exceptions'
require 'candy/crunch'

# Mix me into your classes and Mongo will like them!
module Candy
  
  module ClassMethods
    include Crunch::ClassMethods
    
    # Retrieves an object from Mongo by its ID and returns it.  Returns nil if the ID isn't found in Mongo.
    def find(id)
      if collection.find_one(id)
        self.new({:_candy => id})
      end
    end
    
    # Retrieves a single object from Mongo by its search attributes, or nil if it can't be found.
    def first(conditions={})
      options = extract_options(conditions)
      if record = collection.find_one(conditions, options)
        find(record["_id"])
      else
        nil
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
  
  module InstanceMethods
    include Crunch::InstanceMethods
    
    # We push ourselves into the DB before going on with our day.
    def initialize(*args, &block)
      @__candy = check_for_candy(args) || self.class.collection.insert({})
      super
    end

    # Shortcut to the document ID.
    def id
      @__candy
    end
    
    # Candy's magic ingredient. Assigning to any unknown attribute will push that value into the Mongo collection.
    # Retrieving any unknown attribute will return that value from this record in the Mongo collection.
    def method_missing(name, *args, &block)
      if name =~ /(.*)=$/  # We're assigning
        self.class.collection.update({"_id" => @__candy}, {"$set" => {$1 => args[0]}})
      else
        self.class.collection.find_one(@__candy, :fields => [name.to_s])[name.to_s]
      end
    end
    
  private
  
    # Returns the secret decoder ring buried in the arguments to "new"
    def check_for_candy(args)
      if (candidate = args.pop).is_a?(Hash) and candidate[:_candy]
        candidate[:_candy]
      else # This must not be for us, so put it back  
        args.push candidate if candidate
        nil
      end
    end
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end