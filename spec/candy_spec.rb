require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Candy" do
  # An example class to contain our methods
  class Zagnut
    include Candy
  end
  
  before(:each) do
    @this = Zagnut.new
  end
  
  it "inserts a document immediately" do
    @this.id.should be_a(Mongo::ObjectID)
  end
  
end
