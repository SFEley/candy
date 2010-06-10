require 'candy/crunch'
require 'candy/embeddable'

module Candy
  
  # An array-like object that saves itself to a parent Candy::Piece object.  MongoDB's atomic
  # array operators are used extensively to perform concurrency-friendly updates of individual
  # array elements without rewriting the whole array.
  class CandyArray
    include Crunch
    include Embeddable
    include Enumerable
    
    # Creates the object with parent and attribute values set properly on the object and any children.
    def self.embed(parent, attribute, *args)
      this = self.new(*args)
      this.candy_adopt(parent, attribute)
    end
    
    # Sets the initial array state.
    def initialize(*args)
      @__candy = from_candy(args)
      super()
    end
    
    # Set a value at a specified index in our array.  Note that this operation _does not_ confirm that the 
    # array in Mongo still matches our current state.  If concurrent updates have happened, you might end up
    # overwriting something other than what you thought.
    def []=(index, val)
      property = candy_coat(nil, val)  # There are no attribute names on array inheritance
      @__candy_parent.set embedded(index => property)
      self.candy[index] = property
    end
    
    # Retrieves the value from our internal array.
    def [](index)
      candy[index]
    end
    
    # Iterates over each value in turn, so that we can have proper Enumerable support
    def each(&block)
      candy.each(&block)
    end
    
    # Appends a value to our array.  
    def <<(val)
      property = candy_coat(@__candy_parent_key, val)
      @__candy_parent.operate :push, @__candy_parent_key => property
      self.candy << property
    end
    alias_method :push, :<<
    
    # Pops the front off the MongoDB array and returns it, then resyncs the array.
    # (Thus supporting real-time concurrency for queue-like behavior.)
    def shift(n=1)
      doc = @__candy_parent.collection.find_and_modify query: {"_id" => @__candy_parent.id}, update: {'$pop' => {@__candy_parent_key => -1}}, new: false
      @__candy = from_candy(doc[@__candy_parent_key.to_s])
      @__candy.shift
    end
    
    # Returns the array of memoized values.
    def candy
      @__candy ||= []
    end
    alias_method :to_candy, :candy
    alias_method :to_ary, :candy
    
    # Unwraps all elements of the array, telling them who their parent is.  The attribute doesn't matter because arrays don't have them.
    def from_candy(array)
      array.map {|element| Wrapper.unwrap(element, self)}
    end
    
    # Array equality.
    def ==(val)
      self.to_ary == val
    end
    
    # Array length.
    def length
      self.to_ary.length
    end
    alias_method :size, :length

    protected
    
    # Sets the array.  Primarily used by the .embed class method.
    def candy=(val)
      @__candy = val
    end
  end
end