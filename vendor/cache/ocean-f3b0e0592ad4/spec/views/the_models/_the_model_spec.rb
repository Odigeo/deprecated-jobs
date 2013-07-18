require 'spec_helper'

describe "the_models/_the_model" do
  
  before :each do                     # Must be :each (:all causes all tests to fail)
    Api.stub(:call_p)
    TheModel.destroy_all
    render partial: "the_models/the_model", locals: {the_model: create(:the_model)}
    @json = JSON.parse(rendered)
    @u = @json['the_model']
    @links = @u['_links'] rescue {}
  end


  it "has a named root" do
    @u.should_not == nil
  end


  it "should have three hyperlinks" do
    @links.size.should == 3
  end

  it "should have a self hyperlink" do
    @links.should be_hyperlinked('self', /the_models/)
  end

  it "should have a creator hyperlink" do
    @links.should be_hyperlinked('creator', /api_users/)
  end

  it "should have an updater hyperlink" do
    @links.should be_hyperlinked('updater', /api_users/)
  end


  it "should have a created_at time" do
    @u['created_at'].should be_a String
  end

  it "should have an updated_at time" do
    @u['updated_at'].should be_a String
  end

  it "should have a lock_version field" do
    @u['lock_version'].should be_an Integer
  end
      
end
