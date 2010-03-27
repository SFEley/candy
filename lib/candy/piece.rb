require 'candy/factory'
module Candy
  
  # Handles autopersistence and single-object retrieval for an arbitrary Ruby class.
  # For retrieving many objects, include Candy::Collection somewhere else or use
  # the magic Candy() factory.
  module Piece
    module ClassMethods
      include Crunch::ClassMethods

      # Retrieves a single object from Mongo by its search attributes, or nil if it can't be found.
      def first(conditions={})
        conditions = {'_id' => conditions} unless conditions.is_a?(Hash)
        if record = collection.find_one(conditions)
          self.new(record)
        end
      end
      
      # Performs an 'upsert' into the collection.  The first parameter is a field name or array of fields
      # which act as our "key" fields -- if a document in the system matches the values from the hash,
      # it'll be updated.  Otherwise, an insert will occur.  The second parameter tells us what to set or
      # insert.
      def update(key_or_keys, fields)
        search_keys = {}
        Array(key_or_keys).each do |key|
          search_keys[key] = Wrapper.wrap(fields[key])
        end
        collection.update search_keys, fields, :upsert => true
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
      
    private
      
      # Creates a method in the same namespace as the included class that points to
      # 'first', for easier semantics.
      def self.extended(receiver)
        Factory.magic_method(receiver, 'first', 'conditions={}')
      end
      
    end
    
    
    
    # Our initializer checks the LAST argument passed to it, and pops it off the chain if it's a hash.
    # If the hash contains an '_id' field we assume we're being constructed from a MongoDB document; 
    # otherwise we assume we're a new document and insert ourselves into the database.
    def initialize(*args, &block)
      if args[-1].is_a?(Hash)
        data = args.pop
        if @__candy_id = data.delete('_id')  # We're an existing document
          @__candy = Wrapper.unwrap(data)
        else
          set data   # Insert the data we're given
        end
      end
      super
    end
    
    # Shortcut to the document ID.
    def id
      @__candy_id
    end
    
    # Objects are equal if they point to the same MongoDB record (unless both have IDs of nil, in which case 
    # they're never equal.)
    def ==(subject)
      return false if id.nil?
      return false unless subject.respond_to?(:id)
      self.id == subject.id 
    end
    
    # Candy's magic ingredient. Assigning to any unknown attribute will push that value into the Mongo collection.
    # Retrieving any unknown attribute will return that value from this record in the Mongo collection.
    def method_missing(name, *args, &block)
      if name =~ /(.*)=$/  # We're assigning
        self[$1.to_sym] = args[0]
      elsif name =~ /(.*)\?$/  # We're asking
        (self[$1.to_sym] ? true : false)
      else
        self[name]
      end
    end
    
    
    # Given a Candy integer property, increments it by the given value (which defaults to 1) using the atomic $inc.
    # (Note that we don't actually check the property to make sure it's an integer and $inc is valid. If it isn't, 
    # this operation will silently fail.)
    def inc(property, increment=1)
    end

    # Given a Candy array property, appends a value or values to the end of that array using the atomic $push.  
    # (Note that we don't actually check the property to make sure it's an array and $push is valid. If it isn't, 
    # this operation will silently fail.)
    def push(property, *values)
    end

    # Hash-like getter. If we don't have a value yet, we pull from the database looking for one.
    # Fields pulled from the database are keyed as symbols in the hash.
    def [](key)
      (@__candy ||= retrieve_document || {})[key] 
    end
    
    # Hash-like setter.  Updates the object's internal state, and writes to the database if the state
    # has changed.  Keys should be passed in as symbols for best consistency with the database.
    def []=(key, value)
      unless (@__candy ||= {})[key] == value
        @__candy[key] = value
        set key => value
      end
    end
    
    # Clears memoized data so that the next read pulls from the database.
    def refresh
      @__candy = nil
      self
    end
    
    # Convenience method for debugging.
    def to_s
      "#{self.class.name} (#{id})#{@__candy}"
    end
    
  protected
    # Given a hash of property/value pairs, sets those values in Mongo using the atomic $set if
    # we have a document ID.  Otherwise inserts them and sets the object's ID. 
    def set(fields)
      if @__candy_id
        mongo.update({'_id' => @__candy_id}, {'$set' => Wrapper.wrap(fields)})
      else
        @__candy_id = mongo.insert Wrapper.wrap(fields)
      end
    end
    
    # Pull our document from the database if we know our ID.
    def retrieve_document
      Wrapper.unwrap(mongo.find_one({'_id' => @__candy_id})) if @__candy_id
    end
  
  private
    
    # Shortcut to our class's collection.
    def mongo
      self.class.collection
    end
    
    
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end