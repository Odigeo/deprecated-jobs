require "spec_helper"

describe CronJobsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(get("/v1/cron_jobs")).to route_to("cron_jobs#index")
    end

    it "routes to #create" do
      expect(post("/v1/cron_jobs")).to route_to("cron_jobs#create")
    end

    it "routes to #show" do
      expect(get("/v1/cron_jobs/1")).to route_to("cron_jobs#show", :id => "1")
    end

    it "routes to #update" do
      expect(put("/v1/cron_jobs/1")).to route_to("cron_jobs#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/v1/cron_jobs/1")).to route_to("cron_jobs#destroy", :id => "1")
    end

    it "routes to #execute" do
      expect(put("/v1/cron_jobs/execute")).to route_to("cron_jobs#execute")
    end

  end
end
