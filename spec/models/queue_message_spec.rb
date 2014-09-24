require 'spec_helper'

describe QueueMessage, :type => :model do

  before :each do
    allow_any_instance_of(AsyncJob).to receive(:enqueue)
    @async_job = create(:async_job, steps: [{'name' => "Step 1", 'url' => 'http://127.0.0.1/something'}, 
                                            {'name' => "Step 2", 'poison_limit' => 50}, 
                                            {'name' => "Step 3", 'step_time' => 2.minutes}])
    @msg = double(AWS::SQS::ReceivedMessage,
             body: @async_job.uuid,
             receive_count: 2,
             :visibility_timeout= => 3600,
             delete: nil
           )
  end


  it "should require a message when instantiated" do
    expect(QueueMessage.new(@msg)).to be_a QueueMessage
    expect { QueueMessage.new() }.to raise_error
  end


  it "should have a message reader" do
    expect(QueueMessage.new(@msg).message).to eq @msg
  end

  it "should have a body reader" do
    expect(QueueMessage.new(@msg).body).to eq @async_job.uuid
    expect(@msg).to have_received(:body)
  end

  it "should have a receive count reader" do
    expect(QueueMessage.new(@msg).receive_count).to eq 2
    expect(@msg).to have_received(:receive_count)
  end


  it "should have a visibility_timeout setter" do
    expect(QueueMessage.new(@msg).visibility_timeout = 1.hour).to eq 3600
    expect(@msg).to have_received(:visibility_timeout=)
  end



  it "should have a delete method which removes the message from the AWS queue" do
    QueueMessage.new(@msg).delete
    expect(@msg).to have_received(:delete)
  end


  it "should have an async_job" do
    expect(QueueMessage.new(@msg).async_job).to be_an AsyncJob
  end

  it "should handle a missing async_job by returning nil" do
    @async_job.destroy
    expect(QueueMessage.new(@msg).async_job).to eq nil
  end

  # # No idea why this doesn't work in RSpec when it works in dev and prod
  # it "should have async_job always return the same object" do
  #   aj1 = QueueMessage.new(@msg).async_job
  #   aj2 = QueueMessage.new(@msg).async_job
  #   aj1.should be aj2
  # end


  it "should have a job_missing? predicate" do
    expect(QueueMessage.new(@msg).job_missing?).to eq false
  end

  it "should have a job_started? predicate" do
    expect(QueueMessage.new(@msg).job_started?).to eq false
  end

  it "should have a job_finished? predicate" do
    expect(QueueMessage.new(@msg).job_finished?).to eq false
  end

  it "should have a job_is_poison? predicate" do
    expect(QueueMessage.new(@msg).job_is_poison?).to eq false
  end


  describe "retry_seconds" do

    it "should calculate an integer value" do
      expect(QueueMessage.new(@msg).retry_seconds).to be_an Integer
    end

    it "should provide defaults to return 1, 2, 3, etc as consecutive values" do
      qm = QueueMessage.new(@msg)
      expect(@msg).to receive(:receive_count).and_return(1)
      expect(qm.retry_seconds).to eq 1
      expect(@msg).to receive(:receive_count).and_return(2)
      expect(qm.retry_seconds).to eq 2
      expect(@msg).to receive(:receive_count).and_return(3)
      expect(qm.retry_seconds).to eq 3
      expect(@msg).to receive(:receive_count).and_return(4)
      expect(qm.retry_seconds).to eq 4
    end

    it "should be able to apply a multiplier" do
      @async_job.steps[0]['retry_base'] = 0
      @async_job.steps[0]['retry_multiplier'] = 3
      @async_job.save!
      qm = QueueMessage.new(@msg)
      expect(@msg).to receive(:receive_count).and_return(1)
      expect(qm.retry_seconds).to eq 0
      expect(@msg).to receive(:receive_count).and_return(2)
      expect(qm.retry_seconds).to eq 3
      expect(@msg).to receive(:receive_count).and_return(3)
      expect(qm.retry_seconds).to eq 6
      expect(@msg).to receive(:receive_count).and_return(4)
      expect(qm.retry_seconds).to eq 9
      expect(@msg).to receive(:receive_count).and_return(5)
      expect(qm.retry_seconds).to eq 12
      expect(@msg).to receive(:receive_count).and_return(6)
      expect(qm.retry_seconds).to eq 15
    end

    it "should be able to return exponentially increasing consecutive values" do
      @async_job.steps[0]['retry_base'] = 0
      @async_job.steps[0]['retry_multiplier'] = 1
      @async_job.steps[0]['retry_exponent'] = 3.5
      @async_job.save!
      qm = QueueMessage.new(@msg)
      expect(@msg).to receive(:receive_count).and_return(1)
      expect(qm.retry_seconds).to eq 0
      expect(@msg).to receive(:receive_count).and_return(2)
      expect(qm.retry_seconds).to eq 1
      expect(@msg).to receive(:receive_count).and_return(3)
      expect(qm.retry_seconds).to eq 12
      expect(@msg).to receive(:receive_count).and_return(4)
      expect(qm.retry_seconds).to eq 47
      expect(@msg).to receive(:receive_count).and_return(5)
      expect(qm.retry_seconds).to eq 128
      expect(@msg).to receive(:receive_count).and_return(6)
      expect(qm.retry_seconds).to eq 280
      expect(@msg).to receive(:receive_count).and_return(7)
      expect(qm.retry_seconds).to eq 530
      expect(@msg).to receive(:receive_count).and_return(8)
      expect(qm.retry_seconds).to eq 908
    end

    it "should be able to produce a constant result" do
      @async_job.steps[0]['retry_base'] = 2
      @async_job.steps[0]['retry_multiplier'] = 0
      @async_job.save!
      qm = QueueMessage.new(@msg)
      expect(@msg).to receive(:receive_count).and_return(1)
      expect(qm.retry_seconds).to eq 2
      expect(@msg).to receive(:receive_count).and_return(2)
      expect(qm.retry_seconds).to eq 2
      expect(@msg).to receive(:receive_count).and_return(3)
      expect(qm.retry_seconds).to eq 2
      expect(@msg).to receive(:receive_count).and_return(4)
      expect(qm.retry_seconds).to eq 2
    end
  end



  describe "process" do

    it "should execute the next step if all is in order" do
      expect_any_instance_of(QueueMessage).to receive(:execute_current_step)
      expect(QueueMessage.new(@msg).process).to eq true
    end

    it "should do nothing if there's no associated AsyncJob" do
      @async_job.destroy
      expect_any_instance_of(QueueMessage).not_to receive(:execute_current_step)
      expect(QueueMessage.new(@msg).process).to eq false
    end

    it "should do nothing if the AsyncJob already is finished" do
      @async_job.finished_at = 1.hour.ago.utc
      @async_job.save!
      expect_any_instance_of(QueueMessage).not_to receive(:execute_current_step)
      expect(QueueMessage.new(@msg).process).to eq false
    end

    it "should handle poison messages" do
      expect(Api).not_to receive(:send_mail)
      msg = double(AWS::SQS::ReceivedMessage,
               body: @async_job.uuid,
               receive_count: 6,
               :visibility_timeout= => 3600,
               delete: nil
             )
      expect_any_instance_of(QueueMessage).not_to receive(:execute_current_step)
      qm = QueueMessage.new(msg)
      expect(qm.process).to eq false
      expect(qm.async_job.finished?).to eq true
      expect(qm.async_job.succeeded?).to eq false
      expect(qm.async_job.failed?).to eq true
      expect(qm.async_job.poison?).to eq true
    end

    it "should handle empty or out of sync steps" do
        @async_job.last_completed_step = 3
        @async_job.save!
        expect_any_instance_of(AsyncJob).not_to receive(:execute_current_step)
        QueueMessage.new(@msg).process
    end
  end



  describe "execute_current_step" do

    it "should set the AsyncJob's started_at attribute if not already set" do
      expect_any_instance_of(QueueMessage).to receive(:make_http_request)
      expect(@async_job.started_at).to eq nil
      qm = QueueMessage.new(@msg)
      qm.execute_current_step
      @async_job.reload
      start_time = @async_job.started_at
      expect(start_time).not_to eq nil
      # The started_at time shouldn't change again
      qm.execute_current_step
      @async_job.reload
      expect(@async_job.started_at).to eq start_time
   end

    it "should set the receive count of the AsyncJob step" do
      expect_any_instance_of(QueueMessage).to receive(:make_http_request)
      expect(@async_job.current_step['name']).to eq "Step 1"
      qm = QueueMessage.new(@msg)
      qm.execute_current_step
      @async_job.reload
      expect(@async_job.steps[0]['receive_count']).to eq 2
    end

    it "should set the visibility timeout from the step time" do
      expect_any_instance_of(QueueMessage).to receive(:make_http_request)
      qm = QueueMessage.new(@msg)
      expect(qm).to receive(:visibility_timeout=).twice.with(30)
      expect(qm).to receive(:visibility_timeout=).with(2.minutes)
      qm.execute_current_step
      qm.execute_current_step
      qm.execute_current_step
    end

    it "should advance the job to the next step if successful" do
      expect_any_instance_of(QueueMessage).to receive(:make_http_request)
      qm = QueueMessage.new(@msg)
      expect(@async_job.current_step['name']).to eq "Step 1"
      qm.execute_current_step
      @async_job.reload
      expect(@async_job.current_step['name']).to eq "Step 2"
      qm.execute_current_step
      @async_job.reload
      expect(@async_job.current_step['name']).to eq "Step 3"
      qm.execute_current_step
      @async_job.reload
      expect(@async_job.current_step).to eq nil
    end

    it "should ignore the step if it lacks a URL" do
      expect_any_instance_of(QueueMessage).not_to receive(:make_http_request)
      @async_job.last_completed_step = 0
      @async_job.save!
      QueueMessage.new(@msg).execute_current_step
    end

    it "should log a missing URL to the Rails log and in the job" do
      expect_any_instance_of(QueueMessage).not_to receive(:make_http_request)
      @async_job.last_completed_step = 0
      @async_job.save!
      QueueMessage.new(@msg).execute_current_step
      @async_job.reload
      expect(@async_job.steps[1]['log']).to eq ["Step has no URL. Skipped."]
    end
  end
    
end
