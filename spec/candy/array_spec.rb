require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candy::CandyArray do
    before(:all) do
      @verifier = Zagnut.collection
    end
  
    before(:each) do
      @this = Zagnut.new
      @this.bits = ['peanut', 'almonds', 'titanium']
    end
    
    it "writes the array" do
      @verifier.find_one['bits'][1].should == 'almonds'
    end
    
    it "reads the array" do
      that = Zagnut(@this.id)
      that.bits[2].should == 'titanium'
    end
    
    it "cascades appends" do
      @this.bits << 'kryptonite'
      that = Zagnut(@this.id)
      that.bits[-1].should == 'kryptonite'
    end
    
    it "cascades substitutions" do
      @this.bits[0] = 'raisins'
      that = Zagnut(@this.id)
      that.bits.should == ['raisins', 'almonds', 'titanium']
    end
    
    it "cascades deletions" do
      @this.bits.shift.should == 'peanut'
      that = Zagnut(@this.id)
      that.bits.size.should == 2
    end
    
    it "cascades deeply" do
      @this.bits.push [5, 11, {foo: [:bar]}]
      that = Zagnut(@this.id)
      that.bits[3][2][:foo][0].should == :bar
    end
    
    # Github issue #11
    it "can be updated after load" do
      that = Zagnut(@this.id)
      that.bits << 'schadenfreude'
      @this.refresh
      @this.bits[3].should == 'schadenfreude'
    end

    after(:each) do
      Zagnut.collection.remove
    end
  
end