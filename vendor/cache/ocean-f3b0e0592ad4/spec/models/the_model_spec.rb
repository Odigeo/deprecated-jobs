# == Schema Information
#
# Table name: the_models
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  description  :string(255)      default(""), not null
#  lock_version :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  created_by   :integer          default(0), not null
#  updated_by   :integer          default(0), not null
#

require 'spec_helper'

describe TheModel do

  before :each do
    Api.stub(:call_p)
  end

  
  describe "attributes" do
    
    it "should include a name" do
      create(:the_model, name: "the_model_a").name.should == "the_model_a"
    end

    it "should include a description" do
      create(:the_model, name: "blah", description: "A the_model description").description.should == "A the_model description"
    end
    
    it "should include a lock_version" do
      create(:the_model, lock_version: 24).lock_version.should == 24
    end
    
    it "should have a creation time" do
      create(:the_model).created_at.should be_a Time
    end

    it "should have an update time" do
      create(:the_model).updated_at.should be_a Time
    end
  
   it "should have a creator" do
      create(:the_model, created_by: 123).created_by.should be_an Integer
    end

    it "should have an updater" do
      create(:the_model, updated_by: 123).updated_by.should be_an Integer
    end

 end
    

  describe "search" do
  
    describe ".index" do
    
      before :each do
        create :the_model, name: 'foo', description: "The Foo the_model"
        create :the_model, name: 'bar', description: "The Bar the_model"
        create :the_model, name: 'baz', description: "The Baz the_model"
      end

    
      it "should return an array of TheModel instances" do
        ix = TheModel.index
        ix.length.should == 3
        ix[0].should be_a TheModel
      end
    
      it "should allow matches on name" do
        TheModel.index(name: 'NOWAI').length.should == 0
        TheModel.index(name: 'bar').length.should == 1
        TheModel.index(name: 'baz').length.should == 1
      end
      
      it "should allow searches on description" do
        TheModel.index({}, nil, 'B').length.should == 2
        TheModel.index({}, nil, 'the_model').length.should == 3
      end
      
      it "key/value pairs not in the index_only array should quietly be ignored" do
        TheModel.index(name: 'bar', aardvark: 12).length.should == 1
      end
        
    end
  end

end
