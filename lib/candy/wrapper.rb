require 'mongo'
require 'date'  # Only so we know what one is. Argh.
require 'candy/qualified_const_get'

module Candy
  
  # Utility methods to serialize and unserialize many types of objects into BSON.
  module Wrapper
    
    BSON_SAFE = [String, 
                NilClass, 
                TrueClass, 
                FalseClass, 
                Fixnum, 
                Float, 
                Time,
                Regexp,
                ByteBuffer, 
                Mongo::ObjectID, 
                Mongo::Code,
                Mongo::DBRef]
    
    # Makes an object safe for the sharp pointy edges of MongoDB. Types properly serialized
    # by the BSON.serialize call get passed through unmolested; others are unpacked and their
    # pieces individually shrink-wrapped.
    def self.wrap(thing)
      # Pass the simple cases through
      return thing if BSON_SAFE.include?(thing.class)
      case thing
      when Symbol
        wrap_symbol(thing)
      when Array
        wrap_array(thing)
      when Hash
        wrap_hash(thing)
      when Numeric  # The most obvious are in BSON_SAFE, but not all
        thing
      when Date
        thing.to_time
      # Problem children
      when Proc
        raise TypeError, "Candy can't wrap Proc objects!"
      when Range
        raise TypeError, "Candy can't wrap ranges!"
      else
        wrap_object(thing)  # Our catchall machinery
      end
    end
    
    # Takes an array and returns the same array with unsafe objects wrapped.
    def self.wrap_array(array)
      array.map {|element| wrap(element)}
    end
    
    # Takes a hash and returns it with values wrapped. Keys are left alone.
    def self.wrap_hash(hash)
      wrapped = {}
      hash.each {|k, v| wrapped[k] = wrap(v)}
      wrapped
    end
    
    # Returns a string that's distinctive enough for us to unwrap later and produce the same symbol.
    def self.wrap_symbol(symbol)
      "__sym_" + symbol.to_s
    end
    
    # Returns a nested hash containing the class and instance variables of the object.  It's not the
    # deepest we could ever go (it doesn't handle singleton methods, etc.) but it's a start.
    def self.wrap_object(object)
      wrapped = {"class" => object.class.name}
      ivars = {}
      object.instance_variables.each do |ivar|
        # Different Ruby versions spit different things out for instance_variables.  Annoying.
        ivar_name = '@' + ivar.to_s.sub(/^@/,'')
        ivars[ivar_name] = wrap(object.instance_variable_get(ivar_name))
      end
      wrapped["ivars"] = ivars unless ivars.empty?
      {"__object_" => wrapped}
    end
    
    # Undoes any complicated magic from the Wrapper.wrap method.  Almost everything falls through
    # untouched except for symbol strings and hashed objects.
    def self.unwrap(thing)
      case thing
      when Hash
        if thing["__object_"]
          unwrap_object(thing)
        else
          unwrap_hash(thing)
        end
      when Array
        thing.map {|element| unwrap(element)}
      when /^__sym_(.+)/
        $1.to_sym
      else
        thing
      end
    end
    
    # Traverses the hash, unwrapping both keys and values.  Returns the hash that results.
    def self.unwrap_hash(hash)
      unwrapped = {}
      hash.each {|k,v| unwrapped[unwrap(k)] = unwrap(v)}
      unwrapped
    end
    
    # Turns a hashed object back into an object of the stated class, setting any captured instance 
    # variables.  The main limitation is that the object's class *must* respond to Class.new without 
    # any parameters; we will not attempt to guess at any complex initialization behavior.
    def self.unwrap_object(hash)
      if innards = hash["__object_"]
        klass = Kernel.qualified_const_get(innards["class"])
        object = klass.new
        if innards["ivars"]
          innards["ivars"].each do |name, value|
            object.instance_variable_set(name, unwrap(value))
          end
        end
        object
      end
    end 
  end
end 
