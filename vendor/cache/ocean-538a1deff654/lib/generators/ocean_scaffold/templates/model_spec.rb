require 'spec_helper'

describe <%= class_name %> do


  describe "attributes" do
    
    it "should have a name" do
      create(:<%= singular_name %>).name.should be_a String
    end

    it "should have a description" do
      create(:<%= singular_name %>).description.should be_a String
    end

     it "should have a creation time" do
      create(:<%= singular_name %>).created_at.should be_a Time
    end

    it "should have an update time" do
      create(:<%= singular_name %>).updated_at.should be_a Time
    end
  
   it "should have a creator" do
      create(:<%= singular_name %>).created_by.should be_an Integer
    end

    it "should have an updater" do
      create(:<%= singular_name %>).updated_by.should be_an Integer
    end

  end


  describe "relations" do

    before :each do
      <%= class_name %>.destroy_all
    end


  end



  describe "search" do
    describe ".index_only" do
      it "should return an array of permitted search query args" do
        <%= class_name %>.index_only.should be_an Array
      end
    end
  
    describe ".index" do
    
      before :each do
        create :<%= singular_name %>, name: 'foo', description: "The Foo object"
        create :<%= singular_name %>, name: 'bar', description: "The Bar object"
        create :<%= singular_name %>, name: 'baz', description: "The Baz object"
      end
      
    
      it "should return an array of <%= class_name %> instances" do
        ix = <%= class_name %>.index
        ix.length.should == 3
        ix[0].should be_a <%= class_name %>
      end
    
      it "should allow matches on name" do
        <%= class_name %>.index(name: 'NOWAI').length.should == 0
        <%= class_name %>.index(name: 'bar').length.should == 1
        <%= class_name %>.index(name: 'baz').length.should == 1
      end
      
      it "should allow searches on description" do
        <%= class_name %>.index({}, nil, 'a').length.should == 2
        <%= class_name %>.index({}, nil, 'object').length.should == 3
      end
      
      it "key/value pairs not in the index_only array should quietly be ignored" do
        <%= class_name %>.index(name: 'bar', aardvark: 12).length.should == 1
      end
        
    end
  end

  
  # describe "should permit menu grouping" do
  #   
  #   it "to list the existing apps" do
  #     media = <%= class_name %>.index({}, :app)
  #     media.length.should == 2
  #   end
  #   
  #   it "to give all the contexts in an app" do
  #     media = <%= class_name %>.index({app: 'bar'}, :context)
  #     media.length.should == 2
  #   end
  #   
  #   it "to give all the names in an app and context" do
  #     media = <%= class_name %>.index({app: 'bar', context: 'zoo'}, :name)
  #     media.length.should == 1
  #   end
  #   
  #   it "to list all the locales" do
  #     media = <%= class_name %>.index({}, :locale)
  #     media.length.should == 4
  #   end
  #   
  # end
    
end
