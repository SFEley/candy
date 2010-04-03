require 'candy/array'
require 'candy/embeddable'
require 'candy/factory'
require 'candy/hash'

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
      
      # Makes a new object with a given state that is _not_ immediately saved, but is 
      # held in memory instead.  The principal use for this is to embed it in other 
      # documents.  Except for the unsaved state, this functions identically to 'new'
      # and will pass all its arguments to the initializer.  (Note that you can still 
      # embed documents that _have_ been saved--but then you'll have the data in two
      # places.)
      def embed(*args, &block)
        if args[-1].is_a?(Hash)
          args[-1].merge!(EMBED_KEY => true)
        else
          args.push({EMBED_KEY => true})
        end
        self.new(*args)
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
    
    # HERE STARTETH THE MODULE PROPER.  (The above are the class methods.)
    
    include Embeddable
    
    
    # Our initializer checks the LAST argument passed to it, and pops it off the chain if it's a hash.
    # If the hash contains an '_id' field we assume we're being constructed from a MongoDB document; 
    # otherwise we assume we're a new document and insert ourselves into the database.
    def initialize(*args, &block)
      if args[-1].is_a?(Hash)
        data = args.pop
        if @__candy_id = data.delete('_id')  # We're an existing document
          @__candy = self.from_mongo(Wrapper.unwrap(data))
        elsif data.delete(EMBED_KEY)  # We're being embedded: take any data, but don't save to Mongo
          @__candy = data
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

    # Hash-like getter. If we don't have a value yet, we pull from the database looking for one.
    # Fields pulled from the database are keyed as symbols in the hash.
    def [](key)
      value = (@__candy ||= retrieve_document || {})[key] 
      if value.is_a?(Hash)
        if klass = value.delete(CLASS_KEY)
          @__candy[key] = qualified_const_get(klass).new(value)
        else
          @__candy[key] = CandyHash.embed(value)
        end
      else
        value
      end
    end
    
    # Hash-like setter.  Updates the object's internal state, and writes to the database if the state
    # has changed.  Keys should be passed in as symbols for best consistency with the database.
    def []=(key, value)
      property = embeddify(value)
      (@__candy ||= {})[key] = property
      if property.respond_to?(:to_mongo)
        property.adopt(self, key)
        set key => property.to_mongo
      else
        set key => property
      end
    end
    
    # Clears memoized data so that the next read pulls from the database.
    def refresh
      @__candy = nil
      self
    end
    
    # The MongoDB collection object that everything saves to.  Defaults to the class's
    # collection, which in turn defaults to the classname.
    def collection
      @__candy_collection ||= self.class.collection
    end
    
    # This is normally set at the class level (with a default of the classname) but you
    # can override it on a per-object basis if you need to.
    def collection=(val)
      @__candy_collection = val
    end
    
    # Convenience method for debugging.  Shows the class, the Mongo ID, and the saved state hash.
    def to_s
      "#{self.class.name} (#{id})#{candy.inspect}"
    end
    
    # Returns the hash of memoized values.
    def candy
      @__candy ||= {}
    end
    
    # Converts the object into a hash for MongoDB storage.  Keep in mind that wrapping happens _after_
    # this stage, so it's best to use symbols for keys and leave internal arrays and hashes alone.
    def to_mongo
      candy.merge(CLASS_KEY => self.class.name)
    end
    
    # A hoook for specific object classes to set their internal state using the hash passed in by
    # MongoDB.  If you override this method, delete any hash keys you need for your own purposes
    # and then call 'super' on the remainder.
    def from_mongo(hash) 
      hash
    end
    
    
    # Given a hash of property/value pairs, sets those values in Mongo using the atomic $set if
    # we have a document ID.  Otherwise inserts them and sets the object's ID. 
    def set(fields)
      if @__candy_parent
        @__candy_parent.set embedded(fields)
      elsif id
        collection.update({'_id' => id}, {'$set' => Wrapper.wrap(fields)})
      else
        @__candy_id = collection.insert Wrapper.wrap(fields)
      end
    end
    
    # Pull our document from the database if we know our ID.
    def retrieve_document
      Wrapper.unwrap(collection.find_one({'_id' => id})) if id
    end
  
  private
        
    # If we're an attribute of another object, set our field names accordingly.
    def embedded(fields)
      new_fields = {}
      fields.each{|k,v| new_fields["#{@__candy_parent_key}.#{k}".to_sym] = v}
      new_fields
    end
    
    # Convert hashes and arrays to CandyHashes and CandyArrays.
    def embeddify(value)
      case value
      when CandyHash then value
      when Hash then CandyHash.embed(value)
      when CandyArray then value
      when Array then CandyArray.embed(value)
      else
        value
      end
    end
    
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end