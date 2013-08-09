require "spec_helper"

describe AliveController do
  describe "routing" do

    it "routes to #index" do
      get("/alive").should route_to("alive#index")
    end

  end
end
