require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candy::Piece do
  
  before(:all) do
    @verifier = Zagnut.collection
  end
  
  before(:each) do
    @this = Zagnut.new
  end
  
  it "inserts a document immediately" do
    @this.id.should be_a(Mongo::ObjectID)
  end

  it "saves any attribute it doesn't already handle to the database" do
    @this.bite = "Tasty!"
    @verifier.find_one["bite"].should == "Tasty!"
  end

  it "retrieves any attribute it doesn't already know about from the database" do
    @verifier.update({:_id => @this.id}, {:chew => "Yummy!", :bite => "Ouch."})
    @this.chew.should == "Yummy!"
  end

  it "can roundtrip effectively" do
    @this.swallow = "Gulp."
    @this.swallow.should == "Gulp."
  end

  it "handles missing attributes gracefully" do
    @this.licks.should == nil
  end
  
  it "allows multiple attributes to be set" do
    @this.licks = 7
    @this.center = 0.5
    @this.licks.should == 7
  end
  
  it "can set properties explicity" do
    @this.set(:licks, 17)
    @this.licks.should == 17
  end
  
  it "can set properties from a hash" do
    @this.set(:licks => 19, :center => -2.5)
    @this.licks.should == 19
    @this.center.should == -2.5
  end
  
  it "wraps objects" do
    o = Object.new
    @this.object = o
    @verifier.find_one["object"]["__object_"]["class"].should == "Object"
  end
  
  it "unwraps objects" do
    @verifier.update({:_id => @this.id}, {:center => {"__object_" => {:class => "Object", :ivars => {"@foo" => "bar"}}}})
    @this.center.should be_an(Object)
    @this.center.instance_variable_get(:@foo).should == "bar"
  end
  
  describe "retrieval" do
    it "can find a record by its ID" do
      @this.licks = 10
      that = Zagnut.find(@this.id)
      that.licks.should == 10
    end
    
    it "roundtrips across identical objects" do
      that = Zagnut.find(@this.id)
      @this.calories = 7500
      that.calories.should == 7500
    end
    
    it "returns nil on an object that can't be found" do
      id = Mongo::ObjectID.new
      Zagnut.find(id).should be_nil
    end
    
    it "can get a single object by attributes" do
      @this.pieces = 7.5
      @this.color = "red"
      that = Zagnut.first("pieces" => 7.5)
      that.color.should == "red"
    end
    
    it "returns nil if a first object can't be found" do
      @this.pieces = 11
      Zagnut.first("pieces" => 5).should be_nil
    end
    
    it "can get a single object by attribute method" do
      @this.color = "blue"
      @this.smushy = true
      that = Zagnut.color("blue")
      that.should be_smushy
    end
  end
  
  after(:each) do
    Zagnut.collection.remove
  end
  
end