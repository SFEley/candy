require 'candy/embeddable'

module Candy
  
  # A subclass of Array that saves itself to a parent Candy::Piece object.  MongoDB's atomic
  # array operators are used extensively to perform concurrency-friendly updates of individual
  # array elements without rewriting the whole array.
  class CandyArray < Array
    
    include Embeddable
    
    # Included for purposes of 'embeddable' compatbility, but does nothing except pass its 
    # parameters to the new object.  Since you can't save an array on its own anyway, there's
    # no need to flag it as "don't save."
    def self.embed(*args, &block)
      self.new(*args, &block)
    end
    
    # Pops the front off the MongoDB array and returns it, then resyncs the array.
    # (Thus supporting real-time concurrency for queue-like behavior.)
    def shift(n=1)
      
    end
    
    # Return ourselves as an ordinary (non-Candy) array to be inserted into Mongo.
    def to_mongo
      self.to_a
    end
  end
end