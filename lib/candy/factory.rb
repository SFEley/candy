require 'candy/qualified_const_get'
module Candy
  
  # Utility methods that can generate new methods or classes for some of Candy's magic. 
  module Factory

    # Creates a method with the same name as a provided class, in the same namespace as
    # that class, which delegates to a given class method of that class.  (Whew.  Make sense?)
    def self.magic_method(klass, method, params='')
      ns = namespace(klass)
      my_name = klass.name.sub(ns, '').to_sym
      parent = (ns == '' ? Object : qualified_const_get(ns))
      unless parent.method_defined?(my_name)
        parent.class_eval <<-CLASS
          def #{my_name}(#{params})
            #{klass}.#{method}(#{params.gsub(/\s?=(.+?),/,',')})
          end
        CLASS
      end
    end
      
  private
    # Retrieves the 'BlahModule::BleeModule::' part of a class name, so that we
    # can put other things in the same namespace.
    def self.namespace(receiver)
      receiver.name[/^.*::/] || '' # Hooray for greedy matching
    end
  end
end
    