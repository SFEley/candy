require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Candy" do
  
  before(:each) do
    @this = Zagnut.new
  end  
  
  describe "arrays" do
    it "can push items" do
      @this.push(:colors, 'red')
      @this.colors.should == ['red']
    end
    
    it "can push an array of items" do
      @this.push(:potpourri, 'red', 75, nil)
      @this.potpourri.should == ['red', 75, nil]
    end
  end
  
  describe "numbers" do
    it "can be incremented by 1 when not set" do
      @this.inc(:bites)
      @this.bites.should == 1
    end
    
    it "can be incremented by 1 when set" do
      @this.bites = 11
      @this.inc(:bites)
      @this.bites.should == 12
    end
    
    it "can be incremented by any number" do
      @this.bites = -6
      @this.inc(:bites, 15)
      @this.bites.should == 9
    end
  end
  
  describe "timestamp" do
    it "can be set on creation" do
      Zagnut.class_eval("timestamp :create")
      z = Zagnut.new
      z.created_at.should be_a(Time)
      z.updated_at.should be_nil
    end
    
    it "can be set on modification" do
      Zagnut.class_eval("timestamp :update")
      z = Zagnut.new
      z.created_at.should be_nil
      z.updated_at.should be_nil
      z.bites = 11
      z.created_at.should be_nil
      z.updated_at.should be_a(Time)
    end
    
    it "sets both by default" do
      Zagnut.class_eval("timestamp")
      z = Zagnut.new
      z.bites = 11
      z.created_at.should be_a(Time)
      z.updated_at.should be_a(Time)
    end
    
    describe "question-mark methods" do
      before(:each) do
        @this.tasty = true
        @this.sour = false
        @this.smelly = nil
        @this.color = "yellow"
        @this.pieces = 19
        
      end
      
      it "are true for true values" do
        @this.should be_tasty
      end
      
      it "are true for string values" do
        @this.color?.should be_true
      end
      
      it "are true for numeric values" do
        @this.pieces?.should be_true
      end
      
      it "are false for false values" do
        @this.should_not be_sour
      end
      
      it "are false for nil values" do
        @this.should_not be_smelly
      end
      
      it "are false for undefined values" do
        @this.should_not be_loud
      end
      
      
    end
    
    after(:each) do
      Zagnut.class_eval("timestamp nil")
    end
    
  end
  
  after(:each) do
    Zagnut.collection.remove
  end
  
end
