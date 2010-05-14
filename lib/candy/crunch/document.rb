module Candy
  module Crunch
    
    # MongoDB interface methods specific to the handling of individual documents (as opposed to collections or cursors).
    module Document
      ### RETRIEVAL METHODS
      # Returns the listed fields of the document. If no fields are given, returns the whole document.
      def retrieve(*fields)
        options = (fields.empty? ? {} : {fields: fields})
        from_candy(collection.find_one({'_id' => id}, options)) if id
      end


      # A generic updater that performs the atomic operation specified on a value nested arbitrarily deeply.
      # Operates in "unsafe" mode, meaning that no document errors will be returned and results are not 
      # guaranteed.  The benefit is that it's very, very fast.  Always returns true.
      def operate!(operator, fields)
        operate operator, fields, {safe: false} and true
      end

      # A generic updater that performs the atomic operation specified on a value nested arbitrarily deeply.
      # 
      def operate(operator, fields, options={safe: true})
        if @__candy_parent
          @__candy_parent.operate operator, embedded(fields), options
        else
          @__candy_id = collection.insert({}) unless id   # Ensure we have something to update
          collection.update({'_id' => id}, {"$#{operator}" => Wrapper.wrap(fields)}, options)
        end
      end

      # Given a hash of property/value pairs, sets those values in Mongo using the atomic $set if
      # we have a document ID.  Otherwise inserts them and sets the object's ID.  Operates in 
      # 'unsafe' mode, so database exceptions are not reported but updates are very fast.
      def set!(fields)
        operate! :set, fields
      end

      # Given a hash of property/value pairs, sets those values in Mongo using the atomic $set if
      # we have a document ID.  Otherwise inserts them and sets the object's ID.  Returns the 
      # values passed to it.
      def set(fields)
        operate :set, fields
        fields
      end

      # Increments the specified field by the specified amount (defaults to 1). Does not return the 
      # new value or any document errors.
      def inc!(field, value=1)
        operate! :inc, field: value
      end

      # Increments the specified field by the specified amount (defaults to 1) and returns the 
      # new value.
      def inc(field, value=1)
        operate :inc, field => value
        retrieve(field)[field]
      end
      
    end
  end
end
