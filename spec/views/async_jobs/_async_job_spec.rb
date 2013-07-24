# == Schema Information
#
# Table name: async_jobs
#
#  id                   :integer          not null, primary key
#  uuid                 :string(255)      not null
#  restarts             :integer          default(0), not null
#  state                :string(255)      default(""), not null
#  started_at           :datetime
#  finished_at          :datetime
#  steps                :text
#  lock_version         :integer          default(0), not null
#  created_by           :integer          default(0), not null
#  updated_by           :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  invisible_until      :datetime
#  last_completed_step  :integer
#  max_seconds_in_queue :integer          default(86400), not null
#  destroy_at           :datetime
#

require 'spec_helper'

describe "async_jobs/_async_job" do
  
  before :each do                     # Must be :each (:all causes all tests to fail)
    aj = create :async_job, 
           started_at: 1.hour.ago.utc,
           finished_at: 10.minutes.ago.utc,
           invisible_until: 1.hour.from_now.utc,
           last_completed_step: 2
    render partial: "async_jobs/async_job", locals: {async_job: aj}
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
    @u['started_at'].should be_a String
  end

  it "should have a finish time" do
    @u['finished_at'].should be_a String
  end

  it "should have a steps array" do
    @u['steps'].should == []
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

  it "should have an invisible_until field" do
    @u['invisible_until'].should be_a String
  end
      
  it "should have an last_completed_step field" do
    @u['last_completed_step'].should == 2
  end
      
  it "should have a max_seconds_in_queue of 1 day" do
    @u['max_seconds_in_queue'].should == 1.day
  end

  it "should have a destroy_at time" do
    @u['destroy_at'].should be_a String
  end

end
