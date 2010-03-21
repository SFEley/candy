module Candy
  
  # Handles autopersistence and single-object retrieval for an arbitrary Ruby class.
  # For retrieving many objects, include Candy::Collection somewhere else or use
  # the magic Candy() factory.
  module Piece
    module ClassMethods
      include Crunch::ClassMethods

      # Retrieves a single object from Mongo by its search attributes, or nil if it can't be found.
      def first(conditions={})
        if record = collection.find_one(conditions, {:fields => ['_id']})
          self.new({:_candy => record['_id']})
        end
      end

      # Deep magic!  Finds and returns a single object by the named attribute.
      def method_missing(name, *args, &block)
        if args.size == 1 or args.size == 2     # If we don't have a value, or have more than
          search = {name => args.shift}         # just a simple options hash, this must not be for us.
          search.merge!(args.shift) if args[0]  # We might have other conditions
          first(search)
        else
          super
        end
      end
      
    end
    
    
    
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
        set $1, Wrapper.wrap(args[0])
      elsif name =~ /(.*)\?$/  # We're asking
        true if self.send($1)
      else
        Wrapper.unwrap(self.class.collection.find_one(@__candy, :fields => [name.to_s])[name.to_s])
      end
    end

    # Updates the Mongo document with the given element or elements.
    def update(element)
      self.class.collection.update({"_id" => @__candy}, element)
    end
    
    # Given either a property/value pair or a hash (which can contain several property/value pairs), sets those
    # values in Mongo using the atomic $set. The first form is functionally equivalent to simply using the
    # magic assignment operator; i.e., `me.set(:foo, 'bar')` is the same as `me.foo = bar`.
    def set(*args)
      if args.length > 1  # This is the property/value form
        hash = {args[0] => args[1]}
      else
        hash = args[0]
      end
      update '$set' => hash
    end

    
    # Given a Candy integer property, increments it by the given value (which defaults to 1) using the atomic $inc.
    # (Note that we don't actually check the property to make sure it's an integer and $inc is valid. If it isn't, 
    # this operation will silently fail.)
    def inc(property, increment=1)
      update '$inc' => {property => increment}
    end

    # Given a Candy array property, appends a value or values to the end of that array using the atomic $push.  
    # (Note that we don't actually check the property to make sure it's an array and $push is valid. If it isn't, 
    # this operation will silently fail.)
    def push(property, *values)
      values.each do |value|
        update '$push' => {property => Wrapper.wrap(value)}
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
    
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end