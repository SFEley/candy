require 'candy/crunch'
require 'candy/embeddable'

module Candy
  
  # An array-like object that saves itself to a parent Candy::Piece object.  MongoDB's atomic
  # array operators are used extensively to perform concurrency-friendly updates of individual
  # array elements without rewriting the whole array.
  class CandyArray
    include Crunch
    include Embeddable
    
    # Included for purposes of 'embeddable' compatibility, but does nothing except pass its 
    # parameters to the new object.  Since you can't save an array on its own anyway, there's
    # no need to flag it as "don't save."
    def self.embed(*args, &block)
      self.new(*args, &block)
    end
    
    # Sets the initial array state.
    def initialize(*args, &block)
      @__candy = args
    end
    
    # Set a value at a specified index in our array.  Note that this operation _does not_ confirm that the 
    # array in Mongo still matches our current state.  If concurrent updates have happened, you might end up
    # overwriting something other than what you thought.
    def []=(index, val)
      property = embeddify(val)
      @__candy_parent.set embedded(index => property)
      self.candy[index] = property
    end
    
    # Retrieves the value from our internal array.
    def [](index)
      candy[index]
    end
    
    # Appends a value to our array.  
    def <<(val)
      property = embeddify(val)
      @__candy_parent.operate :push, @__candy_parent_key => property
      self.candy << property
    end
    alias_method :push, :<<
    
    # Pops the front off the MongoDB array and returns it, then resyncs the array.
    # (Thus supporting real-time concurrency for queue-like behavior.)
    def shift(n=1)
      doc = @__candy_parent.findAndModify({"_id" => @__candy_parent.id}, {'$pop' => {@__candy_parent_key => -1}})
      @__candy = doc['value'][@__candy_parent_key.to_s]
      @__candy.shift
    end
    
    # Returns the array of memoized values.
    def candy
      @__candy ||= []
    end
    alias_method :to_mongo, :candy
    alias_method :to_ary, :candy
    
    # Array equality.
    def ==(val)
      self.to_ary == val
    end
    
    # Array length.
    def length
      self.to_ary.length
    end
    alias_method :size, :length

  end
end