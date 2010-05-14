require 'candy/array'
require 'candy/crunch'
require 'candy/embeddable'
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

      # Creates the object with parent and attribute values set properly on the object and any children.
      def embed(parent, attribute, *args)
        this = self.piece(*args)
        this.candy_adopt(parent, attribute)
      end
      
      
      # Makes a new object with a given state that is _not_ immediately saved, but is 
      # held in memory instead.  The principal use for this is to embed it in other 
      # documents.  Except for the unsaved state, this functions identically to 'new'
      # and will pass all its arguments to the initializer.  (Note that you can still 
      # embed documents that _have_ been saved--but then you'll have the data in two
      # places.)
      def piece(*args)
        if args[-1].is_a?(Hash)
          args[-1].merge!(EMBED_KEY => true)
        else
          args.push({EMBED_KEY => true})
        end
        self.new(*args)
      end
      
      
    private
      # Creates a method in the same namespace as the included class that points to
      # 'first', for easier semantics.
      def self.extended(receiver)
        Factory.magic_method(receiver, 'first', 'conditions={}')
      end  
    end
    
    # HERE STARTETH THE MODULE PROPER.  (The above are the class methods.)
    include Crunch
    include Embeddable
    
    
    # Our initializer expects the last argument to be a hash of values. If the hash contains an '_id' 
    # field we assume we're being constructed from a MongoDB document and we unwrap the remaining
    # values; otherwise we assume we're a new document and set any values in the hash as if they
    # were assigned. Any other arguments are not our business and will be passed down the chain.
    def initialize(*args, &block)
      if args[-1].is_a?(Hash)
        data = args.pop
        if data.delete(EMBED_KEY) or @__candy_id = data.delete('_id')  # We're an embedded or existing document
          @__candy = self.from_candy(data)
        else
          data.each {|key, value| send("#{key}=", value)}  # Assign all the data we're given
        end
      end
      super
    end
    
    # Shortcut to the document ID.
    def id
      @__candy_id
    end
        
    
    # Returns the hash of memoized values.
    def candy
      @__candy ||= retrieve || {}
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
      candy[key] 
    end
    
    # Hash-like setter.  Updates the object's internal state, and writes to the database if the state
    # has changed.  Keys should be passed in as symbols for best consistency with the database.
    def []=(key, value)
      property = candy_coat(key, value) # Transform hashes and arrays, and communicate embedding
      candy[key] = property
      set key => property
    end
    
    # Clears memoized data so that the next read pulls from the database.
    def refresh
      @__candy = nil
      self
    end
    
    
    # Convenience method for debugging.  Shows the class, the Mongo ID, and the saved state hash.
    def to_s
      "#{self.class.name} (#{id})#{candy.inspect}"
    end
    
    
    # Converts the object into a hash for MongoDB storage.  Keep in mind that wrapping happens _after_
    # this stage, so it's best to use symbols for keys and leave internal arrays and hashes alone.
    def to_candy
      candy.merge(CLASS_KEY => self.class.name)
    end
    
    # Unwraps the values passed to us from MongoDB, setting parent attributes on any embedded Candy
    # objects.
    def from_candy(hash) 
      unwrapped = {}
      hash.each do |key, value|
        field = Wrapper.unwrap_key(key)
        unwrapped[field] = Wrapper.unwrap(value, self, field)
      end
      unwrapped
    end
    
    
  
  private
        
    
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end