require 'mongo'
require 'etc'  # To get the current username for database default

module Candy
  
  # All of the hard crunchy bits that connect us to a collection within a Mongo database.
  module Crunch
    module ClassMethods
      
      # Passed to the default connection.  It uses the $MONGO_HOST global if that's set and you don't override it.
      def host
        @host ||= $MONGO_HOST
      end

      # Passed to the default connection.  It uses the $MONGO_PORT global if that's set and you don't override it.
      def port
        @port ||= $MONGO_PORT
      end
      
      # A hash passed to the default connection. It uses the $MONGO_OPTIONS global if that's set and you don't override it.
      def options
        @options ||= ($MONGO_OPTIONS || {})
      end
      
      # Overrides the host and resets the connection, db, and collection.
      def host=(val)
        @connection = nil
        @host = val
      end
      
      # Overrides the port and resets the connection, db, and collection.
      def port=(val)
        @connection = nil
        @port = val
      end

      # Overrides the options hash and resets the connection, db, and collection.
      def options=(val)
        @connection = nil
        @options = val
      end
      
      # Returns the connection you gave, or creates a default connection to the default host and port.
      def connection
        @connection ||= Mongo::Connection.new(host, port, options)
      end
       
      # First clears any collection and database we're talking to, then accepts a connection you provide.
      # You're responsible for your own host, port and options if you use this.
      def connection=(val)
        self.db = nil
        @connection = val
      end
      
      # First clears any collection we're talking to, then accepts a database you provide. You can provide a 
      # Mongo::DB object or a string with the database name. If you provide a Mongo::DB object, the default
      # connection is not used, and the :strict flag should be false or default collection lookup will fail.
      def db=(val)
        self.collection = nil
        case val
        when Mongo::DB
          @db = val
        when String
          @db = Mongo::DB.new(val, connection)
        when nil
          @db = nil
        else 
          raise ConnectionError, "The db attribute needs a Mongo::DB object or a name string."
        end
      end
      
      # Returns the database you gave, or creates a default database named for your username (or 'candy' if it
      # can't find a username).
      def db
        @db ||= Mongo::DB.new($MONGO_DB || Etc.getlogin || 'candy', connection, :strict => false)
      end
      
      # Accepts either a Mongo::Collection object or a string with the collection name.  If you provide a 
      # Mongo::Collection object, the default database and connection are not used.
      def collection=(val)
        case val
        when Mongo::Collection
          @collection = val
        when String
          @collection = db.create_collection(val)
        when nil
          @collection = nil
        else
          raise ConnectionError, "The collection attribute needs a Mongo::Collection object or a name string."
        end
      end
      
      # Returns the collection you gave, or creates a default collection named for the current class.
      def collection
        @collection ||= db.create_collection(name)
      end
      
      # Creates an index on the specified property, with an optional direction specified as either :asc or :desc.
      # (Note that this is deliberately a very simple method. If you want multi-key or unique indexes, just call
      # #create_index directly on the collection.)
      def index(property, direction=:asc)
        case direction
        when :asc then mongo_direction = Mongo::ASCENDING
        when :desc then mongo_direction = Mongo::DESCENDING
        else
          raise TypeError, "Index direction should be :asc or :desc"
        end
        collection.create_index(property => mongo_direction)
      end
    end
    
    module InstanceMethods
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end