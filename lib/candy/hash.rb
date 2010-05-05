require 'candy/piece'

module Candy
  
  # A subclass of Hash that behaves like a Candy::Piece.  This class has two major uses:
  #
  # * It's a convenient starting point if you just want to store a bunch of data in Mongo
  #   and don't need to implement any business logic in your own classes; and
  # * It's the default when you embed hashed data in another Candy::Piece and don't
  #   supply another object class. Because it doesn't need to store a classname, using
  #   it means less metadata in your collections.
  #
  # If you don't tell them otherwise, top-level CandyHash objects store themselves in
  # the 'candy' collection.  You can change that at any time by setting a different
  # collection at the class or object level.
  class CandyHash < Hash
    include Crunch
    include Piece
    
    self.collection = 'candy'
    
  
    # Overrides the default behavior in Candy::Piece so that we DO NOT add our
    # class name to the saved values.
    def to_candy
      candy
    end
          
  end
end