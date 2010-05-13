module Candy
  
  # Shared methods to create associations between top-level objects and embedded objects (hashes, 
  # arrays, or Candy::Pieces).
  module Embeddable
        
    # Tells an embedded object about its parent.  When its own state changes, it can use this
    # information to write home and update the parent.
    def candy_adopt(parent, attribute)
      @__candy_parent = parent
      @__candy_parent_key = attribute
      self
    end
    
  private
    # If we're an attribute of another object, set our field names accordingly.
    def embedded(fields)
      new_fields = {}
      fields.each{|k,v| new_fields["#{@__candy_parent_key}.#{k}".to_sym] = v}
      new_fields
    end
  
    # Convert hashes and arrays to CandyHashes and CandyArrays, and set the parent key for any Candy pieces.
    def candy_coat(key, value)
      case value
      when Hash then CandyHash.embed(self, key, value)
      when Array then CandyArray.embed(self, key, *value)   # Explode our array into separate arguments
      when CandyHash then value.candy_adopt(self, key)
      when CandyArray then value.candy_adopt(self, key)
      else
        if value.respond_to?(:candy_adopt)
          value.candy_adopt(self, key)
        else
          value
        end
      end
    end
  
  end
end