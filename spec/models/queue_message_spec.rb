require 'spec_helper'

describe QueueMessage do

  # before :all do
  #   WebMock.allow_net_connect!
  #   AsyncJob.establish_db_connection
  # end

  # after :all do
  #   WebMock.disable_net_connect!
  # end


  before :each do
    AsyncJob.any_instance.stub(:enqueue)
    @async_job = create(:async_job, steps: [{'name' => "Step 1", 'url' => 'http://127.0.0.1/something'}, 
                                            {'name' => "Step 2", 'poison_limit' => 50}, 
                                            {'name' => "Step 3", 'step_time' => 2.minutes}
                                           ])
    @msg = double(AWS::SQS::ReceivedMessage,
             body: @async_job.uuid,
             receive_count: 2,
             :visibility_timeout= => 3600,
             delete: nil
           )
  end


  it "should require a message when instantiated" do
    QueueMessage.new(@msg).should be_a QueueMessage
    expect { QueueMessage.new() }.to raise_error
  end


  it "should have a message reader" do
    QueueMessage.new(@msg).message.should == @msg
  end

  it "should have a body reader" do
    QueueMessage.new(@msg).body.should == @async_job.uuid
    expect(@msg).to have_received(:body)
  end

  it "should have a receive count reader" do
    QueueMessage.new(@msg).receive_count.should == 2
    expect(@msg).to have_received(:receive_count)
  end


  it "should have a visibility_timeout setter" do
    (QueueMessage.new(@msg).visibility_timeout = 1.hour).should == 3600
    expect(@msg).to have_received(:visibility_timeout=)
  end



  it "should have a delete method which removes the message from the AWS queue" do
    QueueMessage.new(@msg).delete
    expect(@msg).to have_received(:delete)
  end


  it "should have an async_job" do
    QueueMessage.new(@msg).async_job.should be_an AsyncJob
  end

  it "should handle a missing async_job by returning nil" do
    @async_job.destroy
    QueueMessage.new(@msg).async_job.should == nil
  end

  # # No idea why this doesn't work in RSpec when it works in dev and prod
  # it "should have async_job always return the same object" do
  #   aj1 = QueueMessage.new(@msg).async_job
  #   aj2 = QueueMessage.new(@msg).async_job
  #   aj1.should be aj2
  # end


  it "should have a job_missing? predicate" do
    QueueMessage.new(@msg).job_missing?.should == false
  end

  it "should have a job_started? predicate" do
    QueueMessage.new(@msg).job_started?.should == false
  end

  it "should have a job_finished? predicate" do
    QueueMessage.new(@msg).job_finished?.should == false
  end

  it "should have a job_is_poison? predicate" do
    QueueMessage.new(@msg).job_is_poison?.should == false
  end


  describe "retry_seconds" do

    it "should calculate an integer value" do
      QueueMessage.new(@msg).retry_seconds.should be_an Integer
    end

    it "should provide defaults to return 1, 2, 3, etc as consecutive values" do
      qm = QueueMessage.new(@msg)
      @msg.should_receive(:receive_count).and_return(1)
      qm.retry_seconds.should == 1
      @msg.should_receive(:receive_count).and_return(2)
      qm.retry_seconds.should == 2
      @msg.should_receive(:receive_count).and_return(3)
      qm.retry_seconds.should == 3
      @msg.should_receive(:receive_count).and_return(4)
      qm.retry_seconds.should == 4
    end

    it "should be able to apply a multiplier" do
      @async_job.steps[0]['retry_base'] = 0
      @async_job.steps[0]['retry_multiplier'] = 3
      @async_job.save!
      qm = QueueMessage.new(@msg)
      @msg.should_receive(:receive_count).and_return(1)
      qm.retry_seconds.should == 0
      @msg.should_receive(:receive_count).and_return(2)
      qm.retry_seconds.should == 3
      @msg.should_receive(:receive_count).and_return(3)
      qm.retry_seconds.should == 6
      @msg.should_receive(:receive_count).and_return(4)
      qm.retry_seconds.should == 9
      @msg.should_receive(:receive_count).and_return(5)
      qm.retry_seconds.should == 12
      @msg.should_receive(:receive_count).and_return(6)
      qm.retry_seconds.should == 15
    end

    it "should be able to return exponentially increasing consecutive values" do
      @async_job.steps[0]['retry_base'] = 0
      @async_job.steps[0]['retry_multiplier'] = 1
      @async_job.steps[0]['retry_exponent'] = 3.5
      @async_job.save!
      qm = QueueMessage.new(@msg)
      @msg.should_receive(:receive_count).and_return(1)
      qm.retry_seconds.should == 0
      @msg.should_receive(:receive_count).and_return(2)
      qm.retry_seconds.should == 1
      @msg.should_receive(:receive_count).and_return(3)
      qm.retry_seconds.should == 12
      @msg.should_receive(:receive_count).and_return(4)
      qm.retry_seconds.should == 47
      @msg.should_receive(:receive_count).and_return(5)
      qm.retry_seconds.should == 128
      @msg.should_receive(:receive_count).and_return(6)
      qm.retry_seconds.should == 280
      @msg.should_receive(:receive_count).and_return(7)
      qm.retry_seconds.should == 530
      @msg.should_receive(:receive_count).and_return(8)
      qm.retry_seconds.should == 908
    end

    it "should be able to produce a constant result" do
      @async_job.steps[0]['retry_base'] = 2
      @async_job.steps[0]['retry_multiplier'] = 0
      @async_job.save!
      qm = QueueMessage.new(@msg)
      @msg.should_receive(:receive_count).and_return(1)
      qm.retry_seconds.should == 2
      @msg.should_receive(:receive_count).and_return(2)
      qm.retry_seconds.should == 2
      @msg.should_receive(:receive_count).and_return(3)
      qm.retry_seconds.should == 2
      @msg.should_receive(:receive_count).and_return(4)
      qm.retry_seconds.should == 2
    end
  end



  describe "process" do

    it "should execute the next step if all is in order" do
      QueueMessage.any_instance.should_receive(:execute_current_step)
      QueueMessage.new(@msg).process.should == true
    end

    it "should do nothing if there's no associated AsyncJob" do
      @async_job.destroy
      QueueMessage.any_instance.should_not_receive(:execute_current_step)
      QueueMessage.new(@msg).process.should == false
    end

    it "should do nothing if the AsyncJob already is finished" do
      @async_job.finished_at = 1.hour.ago.utc
      @async_job.save!
      QueueMessage.any_instance.should_not_receive(:execute_current_step)
      QueueMessage.new(@msg).process.should == false
    end

    it "should handle poison messages" do
      msg = double(AWS::SQS::ReceivedMessage,
               body: @async_job.uuid,
               receive_count: 6,
               :visibility_timeout= => 3600,
               delete: nil
             )
      QueueMessage.any_instance.should_not_receive(:execute_current_step)
      qm = QueueMessage.new(msg)
      qm.process.should == false
      qm.async_job.finished?.should == true
      qm.async_job.succeeded?.should == false
      qm.async_job.failed?.should == true
      qm.async_job.poison?.should == true
    end

    it "should handle empty or out of sync steps" do
        @async_job.last_completed_step = 3
        @async_job.save!
        AsyncJob.any_instance.should_not_receive(:execute_current_step)
        QueueMessage.new(@msg).process
    end
  end



  describe "execute_current_step" do

    it "should set the AsyncJob's started_at attribute if not already set" do
      QueueMessage.any_instance.should_receive(:make_http_request)
      @async_job.started_at.should == nil
      qm = QueueMessage.new(@msg)
      qm.execute_current_step
      @async_job.reload
      start_time = @async_job.started_at
      start_time.should_not == nil
      # The started_at time shouldn't change again
      qm.execute_current_step
      @async_job.reload
      @async_job.started_at.should == start_time
   end

    it "should set the receive count of the AsyncJob step" do
      QueueMessage.any_instance.should_receive(:make_http_request)
      @async_job.current_step['name'].should == "Step 1"
      qm = QueueMessage.new(@msg)
      qm.execute_current_step
      @async_job.reload
      @async_job.steps[0]['receive_count'].should == 2
    end

    it "should set the visibility timeout from the step time" do
      QueueMessage.any_instance.should_receive(:make_http_request)
      qm = QueueMessage.new(@msg)
      qm.should_receive(:visibility_timeout=).twice.with(30)
      qm.should_receive(:visibility_timeout=).with(2.minutes)
      qm.execute_current_step
      qm.execute_current_step
      qm.execute_current_step
    end

    it "should advance the job to the next step if successful" do
      QueueMessage.any_instance.should_receive(:make_http_request)
      qm = QueueMessage.new(@msg)
      @async_job.current_step['name'].should == "Step 1"
      qm.execute_current_step
      @async_job.reload
      @async_job.current_step['name'].should == "Step 2"
      qm.execute_current_step
      @async_job.reload
      @async_job.current_step['name'].should == "Step 3"
      qm.execute_current_step
      @async_job.reload
      @async_job.current_step.should == nil
    end

    it "should ignore the step if it lacks a URL" do
      QueueMessage.any_instance.should_not_receive(:make_http_request)
      @async_job.last_completed_step = 0
      @async_job.save!
      QueueMessage.new(@msg).execute_current_step
    end

    it "should log a missing URL to the Rails log and in the job" do
      QueueMessage.any_instance.should_not_receive(:make_http_request)
      @async_job.last_completed_step = 0
      @async_job.save!
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload
      @async_job.steps[1]['log'].should == ["Step has no URL. Skipped."]
    end
  end
    
end
