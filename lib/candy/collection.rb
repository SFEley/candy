require 'candy/crunch'
require 'active_support'

module Candy
  
  # Handles Mongo queries for a particular named collection.  You can include
  # this in any class, but the class will start to act an awful lot like an
  # Enumerator.  The 'collects' macro is required if you set this up manually
  # instead of with the magic Candy() factory.
  module Collection
    FIND_OPTIONS = %w(
      :fields
      :skip
      :limit
      :sort
      :hint
      :snapshot
      :timeout
    )
    
    include Crunch::InstanceMethods

    module ClassMethods
      include Crunch::ClassMethods
      
      # Sets the collection that all queries run against, qualified by
      # the namespace of the current class.  (This makes it easy to name
      # sibling classes.)
      def collects(something)
        self.collection = name.sub(/#{name.demodulize}$/, something.to_s.classify)
      end
      
      def all
        self.new
      end
      
      def method_missing(name, *args, &block)
        coll = self.new
        coll.send(name, *args, &block)
      end  
    end
   
    def initialize(*args, &block)
      super
      @_candy_query = {}
      if args[0].is_a?(Hash)
        @_candy_options = extract_options(args[0])
        @candy_query.merge!(args[0])
      else
        @_candy_options = {}
      end
      refresh_cursor
    end
    
    def method_missing(name, *args, &block)
      if @_candy_cursor.respond_to?(name)
        @_candy_cursor.send(name, *args, &block)
      elsif FIND_OPTIONS.include?(name)
        @_candy_options[name] = args.shift
        refresh_cursor
        self
      else
        @_candy_query[name] = args.shift
        @_candy_query.merge!(args) if args.is_a?(Hash)
        refresh_cursor
        self
      end
    end
          
          
  private
    def refresh_cursor
      puts "COLLECTION: #{self.class.collection.inspect} WITH #{self.class.collection.count} THINGS"
      @_candy_cursor = self.class.collection.find(@_candy_query, @_candy_options)
    end
    
    def extract_options(hash)
      options = {}
      (FIND_OPTIONS & hash.keys).each do |key|
        options[key] = hash.delete(key)
      end
      options
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
    end
  end
end

