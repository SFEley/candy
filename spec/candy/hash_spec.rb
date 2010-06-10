require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candy::CandyHash do
  before(:all) do
    @verifier = Zagnut.collection
  end

  before(:each) do
    @this = Zagnut.new
    @this.filling = {taste: 'caramel', ounces: 0.75}
  end
  
  it "writes the hash" do
    @verifier.find_one['filling']['ounces'].should == 0.75
  end
  
  it "reads the hash" do
    that = Zagnut(@this.id)
    that.filling.taste.should == 'caramel'
  end
  
  it "reads the hash with brackets" do
    that = Zagnut(@this.id)
    that[:filling][:taste].should == 'caramel'
  end
  
  it "cascades changes" do
    @this.filling[:calories] = 250
    that = Zagnut(@this.id)
    that.filling.calories.should == 250
  end
  
  it "cascades deeply" do
    @this.filling.subfilling = {texture: :gravel}
    that = Zagnut(@this.id)
    that.filling.subfilling.texture.should == :gravel
  end
  
  after(:each) do
    Zagnut.collection.remove
  end
end