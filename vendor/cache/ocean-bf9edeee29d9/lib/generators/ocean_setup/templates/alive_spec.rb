require 'spec_helper'

describe "/alive (for Varnish health checking)" do

  it "should return a 200 with a body of OK" do
    get "/alive", {}, {'HTTP_ACCEPT' => "application/json"}
    response.status.should be(200)
    response.body.should == "ALIVE"
  end
  

end
