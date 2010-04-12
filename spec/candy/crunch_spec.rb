require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'logger'

describe Candy::Crunch do
  
  class PeanutBrittle
    include Candy::Crunch
  end
  
  
  describe "connection" do
    before(:each) do
      # Make sure we don't waste time making bogus connections
      Candy.connection_options[:connect] = false
    end

    it "takes yours if you give it one" do
      c = Mongo::Connection.new('example.org', 11111, :connect => false)
      PeanutBrittle.connection = c
      PeanutBrittle.connection.nodes.should == [["example.org", 11111]]
    end

    it "creates the default connection if you don't give it one" do
      PeanutBrittle.connection.nodes.should == [["localhost", 27017]]
    end
    

    it "uses the Candy.host setting if you don't override it" do
      Candy.host = 'example.net'
      PeanutBrittle.connection.nodes.should == [["example.net", 27017]]
    end

    it "uses the Candy.port setting if you don't override it" do
      Candy.host = 'localhost'
      Candy.port = 33333
      PeanutBrittle.connection.nodes.should == [["localhost", 33333]]
    end

    it "uses the Candy.connection_options setting if you don't override it" do
      l = Logger.new(STDOUT)
      Candy.connection_options = {:logger => l, :connect => false}
      PeanutBrittle.connection.logger.should == Candy.connection_options[:logger]
    end   
    
    it "clears the database when you set it" do
      PeanutBrittle.db.name.should == 'candy_test'
      PeanutBrittle.connection = nil
      PeanutBrittle.instance_variable_get(:@db).should be_nil
    end

    after(:each) do
      Candy.host = nil
      Candy.port = nil
      Candy.connection_options = nil
      PeanutBrittle.connection = nil
    end
  end
  
  describe "database" do
    before(:each) do
      Candy.db = nil
    end
    
    it "takes yours if you give it one" do
      d = Mongo::DB.new('test', PeanutBrittle.connection)
      PeanutBrittle.db = d
      PeanutBrittle.db.name.should == 'test'
    end
  
    it "takes a name if you give it one" do
      PeanutBrittle.db = 'crunchy'
      PeanutBrittle.db.name.should == 'crunchy'
    end
  
    it "throws an exception if you give it a database type it can't recognize" do
      lambda{PeanutBrittle.db = 5}.should raise_error(Candy::ConnectionError, "The db attribute needs a Mongo::DB object or a name string.")
    end
  
    it "uses the Candy.db setting if you don't override it" do
      Candy.db = 'foobar'
      PeanutBrittle.db.name.should == 'foobar'
    end
  
    it "uses your username if you don't give it a default database" do
      Etc.stubs(:getlogin).returns('nummymuffin')
      PeanutBrittle.db.name.should == 'nummymuffin'
    end
  
    it "uses 'candy' for a DB name if it can't find a username" do
      Etc.expects(:getlogin).returns(nil)
      PeanutBrittle.db.name.should == 'candy'
    end
    
    it "clears the collection when you set it" do
      PeanutBrittle.db = 'candy_test'
      PeanutBrittle.collection.name.should == PeanutBrittle.name
      PeanutBrittle.db = nil
      PeanutBrittle.instance_variable_get(:@collection).should be_nil
    end
    
    after(:all) do
      Candy.db = 'candy_test'  # Get back to our starting point
    end
  end
  
  describe "collection" do
    it "takes yours if you give it one" do
      c = Mongo::Collection.new(PeanutBrittle.db, 'blah')
      PeanutBrittle.collection = c
      PeanutBrittle.collection.name.should == 'blah'
    end
  
    it "takes a name if you give it one" do
      PeanutBrittle.collection = 'bleh'
      PeanutBrittle.collection.name.should == 'bleh'
    end
  
    it "defaults to the class name" do
      PeanutBrittle.collection.name.should == PeanutBrittle.name
    end
  
    it "throws an exception if you give it a type it can't recognize" do
      lambda{PeanutBrittle.collection = 17.3}.should raise_error(Candy::ConnectionError, "The collection attribute needs a Mongo::Collection object or a name string.")
    end
  
  end
  
  describe "index" do
    it "can be created with just a property name" do
      PeanutBrittle.index(:blah)
      PeanutBrittle.collection.index_information.values[1]['key'].should == {"blah" => Mongo::ASCENDING}
    end
    
    it "can be created with a direction" do
      PeanutBrittle.index(:fwah, :desc)
      PeanutBrittle.collection.index_information.values[1]['key'].should == {"fwah" => Mongo::DESCENDING}
    end
    
    it "throws an exception if you give it a type other than :asc or :desc" do
      lambda{PeanutBrittle.index(:yah, 5)}.should raise_error(Candy::TypeError, "Index direction should be :asc or :desc")  
    end
    
    after(:each) do
      PeanutBrittle.collection.drop_indexes
    end
  end
  
  after(:each) do
    PeanutBrittle.connection = nil
  end
  
end
