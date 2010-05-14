require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candy::Piece do
  
  class Nougat
    attr_accessor :foo
  end
  
  before(:all) do
    @verifier = Zagnut.collection
  end
  
  before(:each) do
    @this = Zagnut.new
  end
  

  it "lazy inserts" do
    @this.id.should be_nil
  end
  
  it "knows its ID after inserting" do
    @this.name = 'Zagnut'
    @this.id.should be_a(BSON::ObjectID)
  end
  
  
  it "can be given a hash of data to insert immediately" do
    that = Zagnut.new({calories: 500, morsels: "chewy"})
    @verifier.find_one(calories: 500)["morsels"].should == "chewy"
  end

  it "saves any attribute it doesn't already handle to the database" do
    @this.bite = "Tasty!"
    @verifier.find_one["bite"].should == "Tasty!"
  end

  it "retrieves any attribute it doesn't already know about from the database" do
    @this.chew = "Munchy!"
    @verifier.update({:_id => @this.id}, {:chew => "Yummy!"})
    that = Zagnut(@this.id)
    that.chew.should == "Yummy!"
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
  
  
  it "wraps objects" do
    nougat = Nougat.new
    nougat.foo = 5
    @this.center = nougat
    @verifier.find_one["center"]["__object_"]["class"].should == Nougat.name
  end
  
  it "unwraps objects" do
    @this.blank = ""  # To force a save
    center = Nougat.new
    center.foo = :bar
    @verifier.update({'_id' => @this.id}, '$set' => {:center => {"__object_" => {:class => Nougat.name, :ivars => {"@foo" => 'bar'}}}})
    @this.refresh.center.should be_a(Nougat)
    @this.center.instance_variable_get(:@foo).should == 'bar'
  end
  
  it "wraps symbols" do
    @this.crunch = :chomp
    @verifier.find_one["crunch"].should == :chomp
  end

  
  it "considers objects equal if they point to the same MongoDB ref" do
    @this.blank = ""
    that = Zagnut(@this.id)
    that.should == @this
  end
  
  it "considers objects unequal if they don't have the same MongoDB ref" do
    @this.calories = 5
    that = Zagnut.new(calories: 5)
    @this.should_not == that
  end
  
  it "considers objects unequal if this one hasn't been saved yet" do
    that = Zagnut.new
    @this.should_not == that
  end
  
  it "considers objects unequal if compared to something without an id" do
    that = Object.new
    @this.should_not == that
  end
  
  

  describe "retrieval" do
    it "can find a record by its ID" do
      @this.licks = 10
      that = Zagnut.first(@this.id)
      that.licks.should == 10
    end
        
    it "returns nil on an object that can't be found" do
      id = BSON::ObjectID.new
      Zagnut(id).should be_nil
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
    
    it "can get the object by a method at the top level" do
      @this.intensity = :Yowza
      that = Zagnut(@this.id)
      that.intensity.should == :Yowza
    end
    
    it "can get particular attributes" do
      @this.smell = "fruity"
      @this.feel = "rough"
      that = Zagnut(@this.id)
      that.retrieve(:smell)[:smell].should == "fruity" 
      that.retrieve(:smell).should_not have_key(:feel)
    end
    
    # Test class for scoped magic method generation
    class BabyRuth
      include Candy::Piece
    end
    
    it "can get the object by a method within the enclosing namespace" do
      foo = BabyRuth.new
      foo.color = 'green'
      bar = BabyRuth(foo.id)
      bar.color.should == 'green'
    end
    
    # Test class to verify magic method generation doesn't override anything
    def Jawbreaker(param=nil)
      "Broken!"
    end
    
    class Jawbreaker
      include Candy::Piece
    end
    
    it "doesn't create a namespace method if one already exists" do
      too = Jawbreaker.new
      too.calories = 55
      tar = Jawbreaker(too.id)
      tar.should == 'Broken!'
    end
    
  end
  
  describe "updates" do
    before(:each) do
      @this.ounces = 17
      @this.crunchy = :very
      @that = Zagnut.new
      @that.ounces = 11
      @that.crunchy = :very
    end
    
    it "will insert a document if the key field's value isn't found" do
      Zagnut.update(:ounces, {ounces: 15, crunchy: :not_very, flavor: 'butterscotch'})
      @verifier.count.should == 3
      Zagnut.ounces(15).flavor.should == 'butterscotch'
    end
    
    it "will update a document if the key field's value is found" do
      Zagnut.update(:ounces, {ounces: 11, crunchy: :barely, salt: 0})
      @verifier.count.should == 2
      @that.refresh
      @that.crunchy.should == :barely
    end
    
    it "can match on multiple keys" do
      Zagnut.update([:crunchy, :ounces], {ounces: 17, crunchy: :very, calories: 715})
      @verifier.count.should == 2
      @this.refresh
      @this.calories.should == 715
    end
      
    it "won't match on multiple keys if they aren't all found" do
      Zagnut.update([:crunchy, :ounces], {ounces: 11, crunchy: :not_quite, color: 'brown'})
      @verifier.count.should == 3
      Zagnut.crunchy(:not_quite).color.should == 'brown'
    end
    
    it "can increment a value simply" do
      @this.inc(:ounces).should == 18
      @verifier.find_one(ounces: 18)["crunchy"].should == :very
    end
    
    it "can increment a value by a specified positive amount" do
      @this.inc(:ounces, 5).should == 22
      @verifier.find_one(ounces: 22)["crunchy"].should == :very
    end
    
    it "can increment a value by a specified negative amount" do
      @this.inc(:ounces, -5).should == 12
      @verifier.find_one(ounces: 12)["crunchy"].should == :very
    end
    
  end
  
  describe "embedding" do
    describe "Candy objects" do
      before(:each) do
        @inner = KitKat.new
        @inner.crunch = 'wafer'   
        @this.inner = @inner
      end

      it "writes the object" do
        @verifier.find_one['inner']['crunch'].should == 'wafer'
      end
      
      it "reads the object" do
        that = Zagnut(@this.id)
        that.inner.crunch.should == 'wafer'
      end
      
      it "maintains the class" do
        that = Zagnut(@this.id)
        that.inner.should be_a(KitKat)
      end
      
      it "cascades changes" do
        @this.inner.coating = 'chocolate'
        @verifier.find_one['inner']['coating'].should == 'chocolate'
      end
      
      it "cascades deeply" do
        @this.inner.inner = Zagnut.piece(beauty: 'recursive!')
        that = Zagnut(@this.id)
        that.inner.inner.beauty.should == 'recursive!'
      end
    end
    
    
    
    
  end
  
  
  
  
  
  
  after(:each) do
    KitKat.collection.remove
    Zagnut.collection.remove
  end
  
end