require 'bson'
require 'date'  # Only so we know what one is. Argh.
require 'candy/qualified_const_get'

module Candy
  
  # Utility methods to serialize and unserialize many types of objects into BSON.
  module Wrapper
    
    BSON_SAFE = [String, 
                Symbol,
                NilClass, 
                TrueClass, 
                FalseClass, 
                Fixnum, 
                Float, 
                Time,
                Regexp,
                BSON::ByteBuffer, 
                BSON::ObjectID, 
                BSON::Code,
                BSON::DBRef]
    
    # Makes an object safe for the sharp pointy edges of MongoDB. Types properly serialized
    # by the BSON.serialize call get passed through unmolested; others are unpacked and their
    # pieces individually shrink-wrapped.
    def self.wrap(thing)
      # Pass the simple cases through
      return thing if BSON_SAFE.include?(thing.class)
      thing = thing.to_candy if thing.respond_to?(:to_candy)  # Make it sweeter if it can be sweetened
      case thing
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
    
    # Takes a hash and returns it with values wrapped. Symbol keys are reversibly converted to strings.
    def self.wrap_hash(hash)
      wrapped = {}
      hash.each do |key, value|  
        wrapped[wrap_key(key)] = wrap(value)
      end
      wrapped
    end
    
    # Lightly wraps hash keys, converting symbols to strings and wrapping strings in single quotes.
    # Thus, we can recover symbols when we _unwrap_ them later.  Other key types will raise an exception.
    def self.wrap_key(key)
      case key
      when String
        "'#{key}'"
      when Symbol
        key.to_s
      else
        raise TypeError, "Candy field names must be strings or symbols. You gave us #{key.class}: #{key}"
      end
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
    
    # Undoes any magic from the Wrapper.wrap method.  Almost everything falls through
    # untouched except for arrays and hashes. The 'parent' and 'attribute' parameters
    # are for recursively setting the parent properties of embedded Candy objects.
    def self.unwrap(thing, parent=nil, attribute=nil)
      case thing
      when Hash
        if thing.has_key?("__object_")
          unwrap_object(thing)
        else
          unwrap_hash(thing, parent, attribute)
        end
      when Array
        if parent   # We only want to create CandyArrays inside Candy pieces
          CandyArray.embed(parent, attribute, *thing)
        else
          thing.collect {|element| unwrap(element)}
        end
      else
        thing
      end
    end
    
    
    # Returns the hash as a Candy::Piece if a class name is embedded, or a CandyHash object otherwise.
    # The 'parent' and 'attribute' parameters should be set by the caller if this is an embedded
    # Candy object.
    def self.unwrap_hash(hash, parent=nil, attribute=nil)
      if class_name = hash.delete(CLASS_KEY.to_s)
        klass = qualified_const_get(class_name)
      else
        klass = CandyHash
      end
      
      if parent
        klass.embed(parent, attribute, hash)
      else
        klass.piece(hash)
      end
    end
    
    # The inverse of Wrapper.wrap_key -- removes single-quoting from strings and converts other strings 
    # to symbols.
    def self.unwrap_key(key)
      if key =~ /^'(.*)'$/
        $1
      else
        key.to_sym
      end
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
