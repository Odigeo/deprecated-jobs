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


  describe "make_http_request" do

    it "should default to a GET" do
      stub_request(:get, "http://127.0.0.1/something").with(body: '')
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
    end

    it "should do a GET if the method is 'GET'" do
      @async_job.current_step['method'] = 'GET'
      @async_job.save!
      stub_request(:get, "http://127.0.0.1/something").with(body: '')
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
    end

    it "should do a POST if the method is 'POST'" do
      @async_job.current_step['method'] = 'POST'
      @async_job.current_step['body'] = 'This is the body.'
      @async_job.save!
      stub_request(:post, "http://127.0.0.1/something").with(body: "This is the body.")
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
    end

    it "should do a PUT if the method is 'PUT'" do
      @async_job.current_step['method'] = 'PUT'
      @async_job.current_step['body'] = 'This is the body.'
      @async_job.save!
      stub_request(:put, "http://127.0.0.1/something").with(body: "This is the body.")
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
    end

    it "should do a DELETE if the method is 'DELETE'" do
      @async_job.current_step['method'] = 'DELETE'
      @async_job.save!
      stub_request(:delete, "http://127.0.0.1/something").with(body: '')
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
    end

    it "should log an unsupported HTTP method" do
      @async_job.current_step['method'] = 'QUUX'
      @async_job.save!
      Faraday.should_not_receive(:quux)
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
      @async_job.reload
      @async_job.steps[0]['log'].should == ["Unsupported HTTP method 'QUUX'"]
    end

    it "should include extra headers" do
      stub_request(:get, "http://127.0.0.1/something").with(headers: {'X-Api-Token' => 'an-api-token'})
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
    end

    it "should set Content-Type and Accept headers to application/json" do
      stub_request(:get, "http://127.0.0.1/something").with(headers: {'Content-Type' => 'application/json', 
                                                                      'Accept' => 'application/json'})
      @qm = QueueMessage.new(@msg)
      @qm.execute_current_step
    end
  end


  describe "make_http_request exceptions" do

    it "should handle timeouts and log them before re-raising the timeout exception" do
      stub_request(:get, "http://127.0.0.1/something").to_timeout
      @qm = QueueMessage.new(@msg)
      expect { @qm.execute_current_step }.to raise_error
      @async_job.reload
      @async_job.steps[0]['log'].should == ["Faraday::Error::TimeoutError: execution expired"]
    end

    it "should handle exceptions and log them before re-raising them" do
      stub_request(:get, "http://127.0.0.1/something").to_raise("some error")
      @qm = QueueMessage.new(@msg)
      expect { @qm.execute_current_step }.to raise_error
      @async_job.reload
      @async_job.steps[0]['log'].should == ["StandardError: some error"]
    end

    it "should set visibility_timeout in proportion to the number of times the message has been received" do
      stub_request(:get, "http://127.0.0.1/something").to_raise("some error")
      @qm = QueueMessage.new(@msg)
      expect { @qm.execute_current_step }.to raise_error
      expect(@msg).to have_received(:visibility_timeout=).with(30) # This is the initial assignment
      expect(@msg).to have_received(:visibility_timeout=).with(2)  # This is the exception assignment
    end

  end


end
