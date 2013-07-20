require 'spec_helper'

describe "async_jobs/_async_job" do
  
  before :each do                     # Must be :each (:all causes all tests to fail)
    render partial: "async_jobs/async_job", locals: {async_job: create(:async_job)}
    @json = JSON.parse(rendered)
    @u = @json['async_job']
    @links = @u['_links'] rescue {}
  end


  it "has a named root" do
    @u.should_not == nil
  end


  it "should have three hyperlinks" do
    @links.size.should == 3
  end

  it "should have a self hyperlink" do
    @links.should be_hyperlinked('self', /async_jobs/)
  end

  it "should have a creator hyperlink" do
    @links.should be_hyperlinked('creator', /api_users/)
  end

  it "should have an updater hyperlink" do
    @links.should be_hyperlinked('updater', /api_users/)
  end


  it "should have a UUID" do
    @u['uuid'].should be_a String
  end

  it "should have a restart count" do
    @u['restarts'].should be_an Integer
  end

  it "should have a state" do
    @u['state'].should be_a String
  end

  it "should have a start time" do
    @u['started_at'].should == nil
  end

  it "should have a finish time" do
    @u['finished_at'].should == nil
  end

  it "should have a payload" do
    @u['payload'].should == []
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
