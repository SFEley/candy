module Candy
  
  # Handles Mongo queries for a particular named collection.  You can include
  # this in any class, but the class will start to act an awful lot like an
  # Enumerator.  The 'collects' macro is required if you set this up manually
  # instead of with the magic Candy() factory.
  module Collection
    module ClassMethods
      def collects(something)
        
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
    end
  end
end

