require 'spec_helper'

describe QueueMessage do

  before :each do
    AsyncJob.any_instance.should_receive(:enqueue).with().once
    @async_job = create(:async_job, steps: [{'name' => "Step 1", 
                                             'url' => 'http://127.0.0.1/something',
                                             'headers' => {x_api_token: 'an-api-token'}
                                            }])
    @msg = double(AWS::SQS::ReceivedMessage,
             body: @async_job.uuid,
             receive_count: 2,
             :visibility_timeout= => 30,
             delete: nil
           )
  end


  describe "authorisation" do

    it "should authenticate if there's no token" do
      @async_job.token = nil
      @async_job.save!
      stub_request(:post, "http://forbidden.odigeoservices.com/v1/authentications").
        to_return(status: 201, body: '{"authentication": {"token": "hey-i-am-the-token"}}', headers: {'Content-Type'=>'application/json'})
      stub_request(:get, "http://127.0.0.1/something")
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.token.should == "hey-i-am-the-token"
      @async_job.steps[0]['log'].should == ["Authenticated", "Succeeded: 200"]
      @async_job.failed?.should == false
    end

    it "should fail the job if there's no token and authentication fails" do
      @async_job.token = nil
      @async_job.save!
      stub_request(:post, "http://forbidden.odigeoservices.com/v1/authentications").
        to_return(status: 403, body: '', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.token.should == nil
      @async_job.steps[0]['log'].should == ["Failed to authenticate"]
      @async_job.failed?.should == true
      @async_job.finished?.should == true
    end

    it "should authenticate if the main request returns 400 (unknown token)" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 400, headers: {'Content-Type'=>'application/json'}}).then.
        to_return({status: 200, body: '{}', headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, "http://forbidden.odigeoservices.com/v1/authentications").
        to_return(status: 201, body: '{"authentication": {"token": "this-is-a-new-token"}}', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.token.should == "this-is-a-new-token"
      @async_job.steps[0]['log'].should == ["Authenticated", "Succeeded: 200"]
      @async_job.failed?.should == false
   end

    it "should fail the job if the main request returns 400 and authentication fails" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 400, headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, "http://forbidden.odigeoservices.com/v1/authentications").
        to_return(status: 403, body: '', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.token.should == "A-totally-fake-token"
      @async_job.steps[0]['log'].should == ["Failed to authenticate"]
      @async_job.failed?.should == true
      @async_job.finished?.should == true
   end

    it "should authenticate if the main request returns 419 (authentication expired)" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 419, headers: {'Content-Type'=>'application/json'}}).then. 
        to_return({status: 200, body: '{}', headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, "http://forbidden.odigeoservices.com/v1/authentications").
        to_return(status: 201, body: '{"authentication": {"token": "this-is-a-new-token"}}', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.token.should == "this-is-a-new-token"
      @async_job.steps[0]['log'].should == ["Authenticated", "Succeeded: 200"]
      @async_job.failed?.should == false
   end

    it "should fail the job if the main request returns 419 and authentication fails" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 419, headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, "http://forbidden.odigeoservices.com/v1/authentications").
        to_return(status: 403, body: '', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.token.should == "A-totally-fake-token"
      @async_job.steps[0]['log'].should == ["Failed to authenticate"]
      @async_job.failed?.should == true
      @async_job.finished?.should == true
   end

  end


  describe "make_http_request" do

    it "should default to a GET" do
      stub_request(:get, "http://127.0.0.1/something").with(body: '')
      QueueMessage.new(@msg).execute_current_step
    end

    it "should do a GET if the method is 'GET'" do
      @async_job.current_step['method'] = 'GET'
      @async_job.save!
      stub_request(:get, "http://127.0.0.1/something").with(body: '')
      QueueMessage.new(@msg).execute_current_step
    end

    it "should do a POST if the method is 'POST'" do
      @async_job.current_step['method'] = 'POST'
      @async_job.current_step['body'] = 'This is the body.'
      @async_job.save!
      stub_request(:post, "http://127.0.0.1/something").with(body: "This is the body.")
      QueueMessage.new(@msg).execute_current_step
    end

    it "should do a PUT if the method is 'PUT'" do
      @async_job.current_step['method'] = 'PUT'
      @async_job.current_step['body'] = 'This is the body.'
      @async_job.save!
      stub_request(:put, "http://127.0.0.1/something").with(body: "This is the body.")
      QueueMessage.new(@msg).execute_current_step
    end

    it "should do a DELETE if the method is 'DELETE'" do
      @async_job.current_step['method'] = 'DELETE'
      @async_job.save!
      stub_request(:delete, "http://127.0.0.1/something").with(body: '')
      QueueMessage.new(@msg).execute_current_step
    end

    it "should log an unsupported HTTP method" do
      @async_job.current_step['method'] = 'QUUX'
      @async_job.save!
      Faraday.should_not_receive(:quux)
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["Unsupported HTTP method 'QUUX'"]
    end

    it "should include extra headers" do
      stub_request(:get, "http://127.0.0.1/something").with(headers: {'X-Api-Token' => 'an-api-token'})
      QueueMessage.new(@msg).execute_current_step
    end

    it "should set Content-Type and Accept headers to application/json" do
      stub_request(:get, "http://127.0.0.1/something").with(headers: {'Content-Type' => 'application/json', 
                                                                      'Accept' => 'application/json'})
      QueueMessage.new(@msg).execute_current_step
    end

    it "should log a redirect response (3xx) if no Location header, then fail the whole job" do
      stub_request(:get, "http://127.0.0.1/something").
         to_return(status: 301, body: nil, headers: {})
      QueueMessage.new(@msg).execute_current_step # (qm.async_job.current_step, 301, {}, nil)
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["Failed: 301 without Location header"]
      @async_job.failed?.should == true
      @async_job.finished?.should == true
    end

    it "should follow and log a redirect response (3xx) with a Location header" do
      stub_request(:get, "http://127.0.0.1/something").
         to_return(status: 301, body: nil, headers: {location: "http://somewhere.else.com/someplace"})
      stub_request(:get, "http://somewhere.else.com/someplace").
         to_return(status: 301, body: nil, headers: {location: "http://final.com/the_data"})
      stub_request(:get, "http://final.com/the_data").
         to_return(status: 200, body: "Final payload", headers: {})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["Redirect: 301 to http://somewhere.else.com/someplace", 
                                            "Redirect: 301 to http://final.com/the_data", 
                                            "Succeeded: 200"]
      @async_job.failed?.should == false
      @async_job.finished?.should == true
    end
  end


  describe "make_http_request exceptions" do

    it "should handle timeouts and log them before re-raising the timeout exception" do
      stub_request(:get, "http://127.0.0.1/something").to_timeout
      expect { QueueMessage.new(@msg).execute_current_step }.to raise_error
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["Faraday::Error::TimeoutError: execution expired"]
    end

    it "should handle exceptions and log them before re-raising them" do
      stub_request(:get, "http://127.0.0.1/something").to_raise("some error")
      expect { QueueMessage.new(@msg).execute_current_step }.to raise_error
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["StandardError: some error"]
    end

    it "should set visibility_timeout in proportion to the number of times the message has been received" do
      stub_request(:get, "http://127.0.0.1/something").to_raise("some error")
      expect { QueueMessage.new(@msg).execute_current_step }.to raise_error
      expect(@msg).to have_received(:visibility_timeout=).with(30) # This is the initial assignment
      expect(@msg).to have_received(:visibility_timeout=).with(2)  # This is the exception assignment
    end
  end


  describe "handle_response" do

    it "should log a successful response (2xx) and return normally" do
      qm = QueueMessage.new(@msg)
      expect { qm.handle_response(qm.async_job.current_step, 204, {}, nil) }.not_to raise_error
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["Succeeded: 204"]
      @async_job.failed?.should == false
      @async_job.finished?.should == false
    end

    it "should log a client error response (4xx) and fail the whole job" do
      qm = QueueMessage.new(@msg)
      expect { qm.handle_response(qm.async_job.current_step, 403, {}, nil) }.not_to raise_error
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["Failed: 403"]
      @async_job.failed?.should == true
      @async_job.finished?.should == true
    end

    it "should log a server error response (5xx), fail the step, then raise an error to trigger a later retry" do
      qm = QueueMessage.new(@msg)
      expect { qm.handle_response(qm.async_job.current_step, 500, {}, nil) }.to raise_error
      @async_job.reload(consistent: true)
      @async_job.steps[0]['log'].should == ["Remote server error: 500. Retrying via exception."]
      @async_job.failed?.should == false
      @async_job.finished?.should == false
    end

  end



end
