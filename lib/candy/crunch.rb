require 'mongo'
require 'etc'  # To get the current username for database default

module Candy
  # Our option accessors live here so that someone could include just the
  # 'candy/crunch' module and make it standalone.
  
  # Overrides the host and resets the connection, db, and collection.
  def self.host=(val)
    @connection = nil
    @host = val
  end
  
  # Overrides the port and resets the connection, db, and collection.
  def self.port=(val)
    @connection = nil
    @port = val
  end
  
  # Overrides the options hash and resets the connection, db, and collection.
  def self.connection_options=(val)
    @connection = nil
    @connection_options = val
  end
  
  # Passed to the default connection.  If not set, Mongo's default of localhost will be used.
  def self.host
    @host
  end
  
  # Passed to the default connection.  If not set, Mongo's default of 27017 will be used.
  def self.port
    @port
  end
  
  # A hash passed to the default connection.  See the Mongo::Connection documentation for valid options.
  def self.connection_options
    @connection_options ||= {}
  end
  
  # First clears any collection and database we're talking to, then accepts a connection you provide.
  # You're responsible for your own host, port and options if you use this.
  def self.connection=(val)
    self.db = nil
    @connection = val
  end
  
  # Returns the connection you gave, or creates a default connection to the default host and port.
  def self.connection
    @connection ||= Mongo::Connection.new(host, port, connection_options)
  end
  
  # Accepts a database you provide. You can provide a Mongo::DB object or a string with the database
  # name. If you provide a Mongo::DB object, the default connection is not used, and the :strict flag
  # should be false or default collection lookup will fail.
  def self.db=(val)
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
  def self.db
    @db ||= Mongo::DB.new(Etc.getlogin || 'candy', connection, :strict => false)
  end
  
  # All of the hard crunchy bits that connect us to a collection within a Mongo database.
  module Crunch
    module ClassMethods
            
      # Returns the connection you gave, or uses the application-level Candy collection.
      def connection
        @connection ||= Candy.connection
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
      
      # Returns the database you gave, or uses the application-level Candy database.
      def db
        @db ||= Candy.db
      end
      
      # Accepts either a Mongo::Collection object or a string with the collection name.  If you provide a 
      # Mongo::Collection object, the default database and connection are not used.
      def collection=(val)
        case val
        when Mongo::Collection
          @collection = val
        when String
          @collection = db.collection(val)
        when nil
          @collection = nil
        else
          raise ConnectionError, "The collection attribute needs a Mongo::Collection object or a name string."
        end
      end
      
      # Returns the collection you gave, or creates a default collection named for the current class.
      def collection
        @collection ||= db.collection(name)
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
        collection.create_index([[property, mongo_direction]])
      end
    end
    
    # We're implementing FindAndModify on Mongo 1.4 until the Ruby driver gets around to being updated...
    def findAndModify(query, update, sort={})
      command = OrderedHash[
        findandmodify: self.collection.name,
        query: query,
        update: update,
        sort: sort
      ]
      result = self.class.db.command(command)
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
    end
  end
end