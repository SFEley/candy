require 'candy/exceptions'
require 'candy/crunch'

# Mix me into your classes and Mongo will like them!
module Candy
  module ClassMethods
    
  end
  
  module InstanceMethods
    def initialize(*args, &block)
      @__candy = self.class.collection.insert({})
      super
    end

    def id
      @id
    end
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end