require "spec_helper"

describe AsyncJobsController, :type => :routing do
  describe "routing" do

    it "doesn't route to #index" do
      expect(get("/v1/async_jobs")).not_to be_routable
    end

    it "routes to #show" do
      expect(get("/v1/async_jobs/1")).to route_to("async_jobs#show", :id => "1")
    end

    it "routes to #create" do
      expect(post("/v1/async_jobs")).to route_to("async_jobs#create")
    end

    it "routes to #update" do
      expect(put("/v1/async_jobs/1")).not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete("/v1/async_jobs/1")).to route_to("async_jobs#destroy", :id => "1")
    end

    it "routes to #cleanup" do
      expect(put("/v1/async_jobs/cleanup")).to route_to("async_jobs#cleanup")
    end
  end
end
