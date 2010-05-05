module Candy
  
  # Shared methods to create associations between top-level objects and embedded objects (hashes, 
  # arrays, or Candy::Pieces).
  module Embeddable
    # Tells an embedded object about its parent.  When its own state changes, it can use this
    # information to write home and update the parent.
    def candy_adopt(parent, attribute)
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
  
    # Convert hashes and arrays to CandyHashes and CandyArrays, and set the parent key for any Candy pieces.
    def candy_coat(key, value)
      piece = case value
        when CandyHash then value
        when Hash then CandyHash.embed(value)
        when CandyArray then value
        when Array then CandyArray.embed(*value)   # Explode our array into separate arguments
        else
          value
        end
      piece.candy_adopt(self, key) if piece.respond_to?(:candy_adopt)
      piece
    end
  
  end
end