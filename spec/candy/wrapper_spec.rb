require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Candy
  describe Candy::Wrapper do
    
    # A simple class to test argument encoding
    class Missile
      attr_accessor :payload
      attr_accessor :rocket

      def explode
        "Dropped the #{payload}."
      end
    end
    
    describe "wrapping" do

      it "can wrap an array of simple arguments" do
        a = ["Hi", 1, nil, 17.536]
        Wrapper.wrap_array(a).should == a
      end
  
      it "can wrap a string" do
        Wrapper.wrap("Hi").should == "Hi"
      end

      it "can wrap nil" do
        Wrapper.wrap(nil).should == nil
      end
  
      it "can wrap true" do
        Wrapper.wrap(true).should be_true
      end
  
      it "can wrap false" do
        Wrapper.wrap(false).should be_false
      end
  
      it "can wrap an integer" do
        Wrapper.wrap(5).should == 5
      end
  
      it "can wrap a float" do
        Wrapper.wrap(17.950).should == 17.950
      end
  
      it "can wrap an already serialized bytestream" do
        b = BSON.serialize(:foo => 'bar')
        Wrapper.wrap(b).should == b
      end
  
      it "can wrap an ObjectId" do
        i = BSON::ObjectId.new
        Wrapper.wrap(i).should == i
      end

      it "can wrap the time" do
        t = Time.now
        Wrapper.wrap(t).should == t
      end
  
      it "can wrap a regular expression" do
        r = /ha(l+)eluja(h?)/i
        Wrapper.wrap(r).should == r
      end
  
      it "can wrap a Mongo code object (if we ever need to)" do
        c = BSON::Code.new('5')
        Wrapper.wrap(c).should == c
      end
  
      it "can wrap a Mongo DBRef (if we ever need to)" do
        d = BSON::DBRef.new('foo', BSON::ObjectId.new)
        Wrapper.wrap(d).should == d
      end
  
      it "can wrap a date as a time" do
        d = Date.today
        Wrapper.wrap(d).should == Date.today.to_time
      end
  
      it "can wrap other numeric types (which might throw exceptions later but oh well)" do
        c = Complex(2, 5)
        Wrapper.wrap(c).should == c
      end
  
      it "wraps an array recursively" do
        a = [5, 'hi', [':symbol', 0], nil]
        Wrapper.wrap(a).should == a
      end
    
      it "wraps keys lightly" do
        h = {"foo" => "bar", :yoo => "yar"}
        Wrapper.wrap(h).keys.should == ["'foo'", "yoo"]
      end
  
      it "wraps a hash's values" do
        h = {:foo => :bar, :yoo => [:yar, 5]}
        Wrapper.wrap(h).values.should == [:bar, [:yar, 5]]
      end
    
      it "rejects procs" do
        p = Proc.new {puts "This should fail!"}
        lambda{Wrapper.wrap(p)}.should raise_error(TypeError)
      end
      
      it "rejects ranges" do
        r = (1..3)
        lambda{Wrapper.wrap(r)}.should raise_error(TypeError)
      end
    
      describe "objects" do
        before(:each) do
          @missile = Missile.new
          @missile.payload = "15 megatons"
          @missile.rocket = [2, Object.new]
          @this = Wrapper.wrap(@missile)
        end
      
        it "returns a hash" do
          @this.should be_a(Hash)
        end
      
        it "keys the hash to be an object" do
          @this.keys.should == ["__object_"]
        end
      
        it "knows the object's class" do
          @this["__object_"]["class"].should =~ /Missile$/
        end
      
        it "captures all the instance variables" do
          ivars = @this["__object_"]["ivars"]
          ivars.should have(2).elements
          ivars["@payload"].should == "15 megatons"
          ivars["@rocket"][1]["__object_"]["class"].should == "Object"
        end
      
          
      
      end
    end
  
    describe "unwrapping" do
      before(:each) do
        @wrapped = {"__object_" => {
          "class" => Missile.name,
          "ivars" => {
            "@payload" => "6 kilotons",
            "@rocket" => [1, {"__object_" => {
              "class" => "Object"
            }}]
          }
        }}
      end
      it "passes most things through untouched" do
        Wrapper.unwrap(5).should == 5
      end
    
    
      it "turns hashed objects back into objects" do
        obj = Wrapper.unwrap(@wrapped)
        obj.should be_a(Missile)
        obj.payload.should == "6 kilotons"
        obj.rocket[0].should == 1
        obj.rocket[1].should be_an(Object)
      end
      
      it "doesn't turn arrays into CandyArrays inside non-Candy objects" do
        obj = Wrapper.unwrap(@wrapped)
        obj.rocket.should_not be_a(CandyArray)
      end
      
      it "traverses a hash and unwraps whatever it needs to" do
        hash = {"foo" => :bar, "'missile'" => @wrapped}
        unwrapped = Wrapper.unwrap(hash)
        unwrapped[:foo].should == :bar
        unwrapped["missile"].should be_a(Missile)
      end
    
      it "traverses an array and unwraps whatever it needs to" do
        array = [:foo, 5, @wrapped, nil, "hi"]
        unwrapped = Wrapper.unwrap(array)
        unwrapped[0].should == :foo
        unwrapped[1].should == 5
        unwrapped[2].should be_a(Missile)
        unwrapped[3].should be_nil
        unwrapped[4].should == "hi"
      end
      
  
    end

    describe "key names" do
      it "can wrap symbols" do
        Wrapper.wrap_key(:foo).should == 'foo'
      end
      
      it "can wrap strings" do
        Wrapper.wrap_key('foo').should == "'foo'"
      end
      
      it "refuses to wrap complicated objects" do
        lambda{Wrapper.wrap_key(Object.new)}.should raise_error(TypeError, /Object/)
      end
      
      it "can unwrap symbols" do
        Wrapper.unwrap_key('foo').should == :foo
      end
      
      it "can unwrap strings" do
        Wrapper.unwrap_key("'foo'").should == 'foo'
      end
    end
    
  end
end