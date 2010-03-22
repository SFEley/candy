require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candy::Collection do
  
  before(:each) do
    @this = Zagnut.new
    @this.color = "red"
    @this.weight = 11.8
    @that = Zagnut.new
    @that.color = "red"
    @that.pieces = 6
    @that.weight = -5
    @the_other = Zagnut.new
    @the_other.color = "blue"
    @the_other.pieces = 7
    @the_other.weight = 0
  end

  
  it "can get all objects matching a search condition" do
    those = Zagnuts.color("red")
    those.count.should == 2
  end
    
  it "can get all objects in a collection" do
    those = Zagnuts.all
    those.count.should == 3
  end
  
  it "still returns if nothing matches" do
    Zagnuts.color("green").to_a.should == []
  end
  
  it "can take options" do
    those = Zagnuts.color("red").sort("weight", :down)
    those.collect{|z| z.weight}.should == [11.8, -5]
  end
  
  it "can be iterated" do
    these = Zagnuts.color("red").sort(:weight)
    this = these.first
    this.pieces.should == 6
    this.weight.should == -5
    this = these.next
    this.pieces.should be_nil
    this.weight.should == 11.8
  end
  
  it "can take scoping on a class or instance level" do
    these = Zagnuts.color("red")
    these.pieces(6)
    these.count.should == 1
  end
  
  it "can get the collection by a method at the top level" do
    these = Zagnuts
    these.count.should == 3
  end
  
  # Test class for scoped magic method generation
  class BabyRuth
    include Candy::Piece
  end
  
  class BabiesRuth
    include Candy::Collection
    collects :baby_ruth
  end
  
  it "can get the object by a method within the enclosing namespace" do
    foo = BabyRuth.new
    foo.color = 'green'
    bar = BabiesRuth(color: 'green')
    bar.count.should == 1
  end
  
  # Test class to verify magic method generation doesn't override anything
  def Jawbreakers(param=nil)
    "Broken everywhere!"
  end
  
  class Jawbreaker
    include Candy::Piece
  end
  
  class Jawbreakers
    include Candy::Collection
    collects :jawbreaker
  end
  
  it "doesn't create a namespace method if one already exists" do
    too = Jawbreaker.new
    too.calories = 55
    tar = Jawbreakers()
    tar.should == 'Broken everywhere!'
  end
  

  after(:each) do
    Zagnut.collection.remove
  end
end