require 'spec_helper'

describe "cron_jobs/_cron_job", :type => :view do

  before :each do                     # Must be :each (:all causes all tests to fail)
    job = create :cron_job, 
                name: "The name", 
                description: "The description",
                cron: "@hourly"
    render partial: "cron_jobs/cron_job", locals: {cron_job: job}
    @json = JSON.parse(rendered)
    @u = @json['cron_job']
    @links = @u['_links'] rescue {}
  end


  it "has a named root" do
    expect(@u).not_to eq nil
  end


  it "should have three hyperlinks" do
    expect(@links.size).to eq 3
  end

  it "should have a self hyperlink" do
    expect(@links).to be_hyperlinked('self', /cron_jobs/)
  end

  it "should have a creator hyperlink" do
    expect(@links).to be_hyperlinked('creator', /api_users/)
  end

  it "should have an updater hyperlink" do
    expect(@links).to be_hyperlinked('updater', /api_users/)
  end


  it "should have a name" do
    expect(@u['name']).to eq "The name"
  end

  it "should have a description" do
    expect(@u['description']).to eq "The description"
  end

  it "should have an enabled boolean" do
    expect(@u['enabled']).to eq true
  end

  it "should have a CRON string" do
    expect(@u['cron']).to eq "@hourly"
  end


  it "should have a steps array" do
    expect(@u['steps']).to eq []
  end

  it "should have a created_at time" do
    expect(@u['created_at']).to be_a String
  end

  it "should have an updated_at time" do
    expect(@u['updated_at']).to be_a String
  end

  it "should have a lock_version field" do
    expect(@u['lock_version']).to be_an Integer
  end
      
  it "should have a max_seconds_in_queue of 1 day" do
    expect(@u['max_seconds_in_queue']).to eq 1.day
  end

  it "should NOT expose the credentials" do
    expect(@u['credentials']).to eq nil
  end

  it "should NOT expose the token" do
    expect(@u['token']).to eq nil
  end

  it "should have a default_step_time of 30 seconds" do
    expect(@u['default_step_time']).to eq 30
  end

end
