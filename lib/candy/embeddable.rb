module Candy
  
  # Shared methods to create associations between top-level objects and embedded objects (hashes, 
  # arrays, or Candy::Pieces).
  module Embeddable
    # Tells an embedded object whom it belongs to and what attribute it's associated with.  When
    # its own state changes, it can use this information to update the parent.
    def adopt(parent, attribute)
      @__candy_parent = parent
      @__candy_parent_key = attribute
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
      when Array then CandyArray.embed(*value)   # Explode our array into separate arguments
      else
        value
      end
    end
  
  end
end