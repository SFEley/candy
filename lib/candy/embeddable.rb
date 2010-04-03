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
    
  end
end