require 'spec_helper'

describe QueueMessage, :type => :model do

  before :each do
    expect_any_instance_of(AsyncJob).to receive(:enqueue).once
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

    @auth_url = INTERNAL_OCEAN_API_URL + "/v1/authentications"
  end


  describe "authorisation" do

    it "should authenticate if there's no token" do
      @async_job.token = nil
      @async_job.save!
      stub_request(:post, @auth_url).
        to_return(status: 201, body: '{"authentication": {"token": "hey-i-am-the-token"}}', headers: {'Content-Type'=>'application/json'})
      stub_request(:get, "http://127.0.0.1/something")
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.token).to eq "hey-i-am-the-token"
      expect(@async_job.steps[0]['log']).to eq ["Authenticated", "Succeeded: 200"]
      expect(@async_job.failed?).to eq false
    end

    it "should fail the job if there's no token and authentication fails" do
      @async_job.token = nil
      @async_job.save!
      stub_request(:post, @auth_url).
        to_return(status: 403, body: '', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.token).to eq ""
      expect(@async_job.steps[0]['log']).to eq ["Failed to authenticate"]
      expect(@async_job.failed?).to eq true
      expect(@async_job.finished?).to eq true
    end

    it "should authenticate if the main request returns 400 (unknown token)" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 400, headers: {'Content-Type'=>'application/json'}}).then.
        to_return({status: 200, body: '{}', headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, @auth_url).
        to_return(status: 201, body: '{"authentication": {"token": "this-is-a-new-token"}}', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Authenticated", "Succeeded: 200"]
      expect(@async_job.token).to eq "this-is-a-new-token"
      expect(@async_job.failed?).to eq false
   end

    it "should fail the job if the main request returns 400 and authentication fails" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 400, headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, @auth_url).
        to_return(status: 403, body: '', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.token).to eq "A-totally-fake-token"
      expect(@async_job.steps[0]['log']).to eq ["Failed to authenticate"]
      expect(@async_job.failed?).to eq true
      expect(@async_job.finished?).to eq true
   end

    it "should authenticate if the main request returns 419 (authentication expired)" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 419, headers: {'Content-Type'=>'application/json'}}).then. 
        to_return({status: 200, body: '{}', headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, @auth_url).
        to_return(status: 201, body: '{"authentication": {"token": "this-is-a-new-token"}}', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Authenticated", "Succeeded: 200"]
      expect(@async_job.token).to eq "this-is-a-new-token"
      expect(@async_job.failed?).to eq false
   end

    it "should fail the job if the main request returns 419 and authentication fails" do
      stub_request(:get, "http://127.0.0.1/something").
        to_return({status: 419, headers: {'Content-Type'=>'application/json'}})
      stub_request(:post, @auth_url).
        to_return(status: 403, body: '', headers: {'Content-Type'=>'application/json'})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.token).to eq "A-totally-fake-token"
      expect(@async_job.steps[0]['log']).to eq ["Failed to authenticate"]
      expect(@async_job.failed?).to eq true
      expect(@async_job.finished?).to eq true
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
      @async_job.current_step['body'] = {"a"=>1, "b"=>"foo"}
      @async_job.save!
      stub_request(:post, "http://127.0.0.1/something").with(body: '{"a":1,"b":"foo"}')
      QueueMessage.new(@msg).execute_current_step
    end

    it "should do a PUT if the method is 'PUT'" do
      @async_job.current_step['method'] = 'PUT'
      @async_job.current_step['body'] = {}
      @async_job.save!
      stub_request(:put, "http://127.0.0.1/something").with(body: "{}")
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
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Unsupported HTTP method 'QUUX'"]
    end

    it "should include extra headers" do
      stub_request(:get, "http://127.0.0.1/something").with(headers: {'X-Api-Token' => 'an-api-token'})
      QueueMessage.new(@msg).execute_current_step
    end

    it "should set only the Accept header to application/json for a GET" do
      stub_request(:get, "http://127.0.0.1/something").with(headers: {'Accept' => 'application/json'})
      QueueMessage.new(@msg).execute_current_step
    end

    it "should log a redirect response (3xx) if no Location header, then fail the whole job" do
      stub_request(:get, "http://127.0.0.1/something").
         to_return(status: 301, body: nil, headers: {})
      QueueMessage.new(@msg).execute_current_step # (qm.async_job.current_step, 301, {}, nil)
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Failed: 301 without Location header"]
      expect(@async_job.failed?).to eq true
      expect(@async_job.finished?).to eq true
    end

    it "should follow and log a redirect response (3xx) with a Location header" do
      stub_request(:get, "http://127.0.0.1/something").
         to_return(status: 301, body: nil, headers: {location: "http://somewhere.else.com/someplace"})
      stub_request(:get, "http://somewhere.else.com/someplace").
         to_return(status: 301, body: nil, headers: {location: "http://final.com/the_data"})
      stub_request(:get, "http://final.com/the_data").
         to_return(status: 200, body: nil, headers: {})
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Redirect: 301 to http://somewhere.else.com/someplace", 
                                            "Redirect: 301 to http://final.com/the_data", 
                                            "Succeeded: 200"]
      expect(@async_job.failed?).to eq false
      expect(@async_job.finished?).to eq true
    end
  end


  describe "make_http_request exceptions" do

    it "should handle timeouts and log them before re-raising the timeout exception" do
      expect(Api).to receive(:request).and_return(double(timed_out?: true))
      expect { QueueMessage.new(@msg).execute_current_step }.to raise_error
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Exception: Ocean API request timed out"]
    end

    it "should handle exceptions and log them before re-raising them" do
      stub_request(:get, "http://127.0.0.1/something").to_raise("some error")
      expect { QueueMessage.new(@msg).execute_current_step }.to raise_error
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["StandardError: some error"]
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
      expect { qm.handle_response(qm.async_job.current_step, 204, {'foo' => 'bar'}, [1, 2]) }.not_to raise_error
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Succeeded: 204"]
      expect(@async_job.failed?).to eq false
      expect(@async_job.finished?).to eq false
      expect(@async_job.last_status).to eq 204
      expect(@async_job.last_headers).to eq({'foo' => 'bar'})
      expect(@async_job.last_body).to eq [1, 2]
    end

    it "should log a client error response (4xx) and fail the whole job" do
      qm = QueueMessage.new(@msg)
      expect { qm.handle_response(qm.async_job.current_step, 403, {'foo' => 'bar'}, [1, 2]) }.not_to raise_error
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Failed: 403"]
      expect(@async_job.failed?).to eq true
      expect(@async_job.finished?).to eq true
      expect(@async_job.last_status).to eq 403
      expect(@async_job.last_headers).to eq({'foo' => 'bar'})
      expect(@async_job.last_body).to eq [1, 2]
    end

    it "should log a server error response (5xx), fail the step, then raise an error to trigger a later retry" do
      qm = QueueMessage.new(@msg)
      expect { qm.handle_response(qm.async_job.current_step, 500, {'foo' => 'bar'}, [1, 2]) }.to raise_error
      @async_job.reload(consistent: true)
      expect(@async_job.steps[0]['log']).to eq ["Remote server error: 500. Retrying via exception."]
      expect(@async_job.failed?).to eq false
      expect(@async_job.finished?).to eq false
      expect(@async_job.last_status).to eq 500
      expect(@async_job.last_headers).to eq({'foo' => 'bar'})
      expect(@async_job.last_body).to eq [1, 2]
    end

  end



end
