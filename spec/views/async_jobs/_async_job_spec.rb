require 'spec_helper'

describe "async_jobs/_async_job", :type => :view do

  before :each do                     # Must be :each (:all causes all tests to fail)
    #AsyncJob.any_instance.should_receive(:enqueue)
    aj = create :async_job, 
           started_at: 1.hour.ago.utc,
           finished_at: 10.minutes.ago.utc,
           last_completed_step: 2,
           last_status: 200,
           last_headers: {},
           last_body: ["foo"]
    render partial: "async_jobs/async_job", locals: {async_job: aj}
    @json = JSON.parse(rendered)
    @u = @json['async_job']
    @links = @u['_links'] rescue {}
  end


  it "has a named root" do
    expect(@u).not_to eq nil
  end


  it "should have three hyperlinks" do
    expect(@links.size).to eq 3
  end

  it "should have a self hyperlink" do
    expect(@links).to be_hyperlinked('self', /async_jobs/)
  end

  it "should have a creator hyperlink" do
    expect(@links).to be_hyperlinked('creator', /api_users/)
  end

  it "should have an updater hyperlink" do
    expect(@links).to be_hyperlinked('updater', /api_users/)
  end


  it "should have a UUID" do
    expect(@u['uuid']).to be_a String
  end

  it "should have a start time" do
    expect(@u['started_at']).to be_a String
  end

  it "should have a finish time" do
    expect(@u['finished_at']).to be_a String
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
      
  it "should have an last_completed_step field" do
    expect(@u['last_completed_step']).to eq 2
  end
      
  it "should have a max_seconds_in_queue of 1 day" do
    expect(@u['max_seconds_in_queue']).to eq 1.day
  end

  it "should have a destroy_at time" do
    expect(@u['destroy_at']).to be_a String
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

  it "should have a succeeded boolean" do
    expect(@u['succeeded']).to eq false
  end

  it "should have a failed boolean" do
    expect(@u['failed']).to eq false
  end

  it "should have a poison boolean" do
    expect(@u['poison']).to eq false
  end

  it "should have a last_status" do
    expect(@u['last_status']).to eq 200
  end

  it "should have a last_headers" do
    expect(@u['last_headers']).to be_a Hash
  end

  it "should have a last_body" do
    expect(@u['last_body']).to eq ["foo"]
  end

end
