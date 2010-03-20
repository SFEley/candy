require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Candy" do
  
  before(:each) do
    @this = Zagnut.new
  end  
  
  
  after(:each) do
    Zagnut.collection.remove
  end
  
end
