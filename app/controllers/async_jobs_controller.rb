class AsyncJobsController < ApplicationController

  ocean_resource_controller required_attributes: []  # PUT isn't used: no required args

  # The following params are required:
  #   :credentials
  # The following params are permitted:
  #   :token, :steps, :max_seconds_in_queue, :default_poison_limit, default_step_time


  respond_to :json
  
  before_action :require_conditional, only: :show
  before_action :find_async_job, :only => [:show, :destroy]
    

  # GET /async_jobs/1
  def show
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(@async_job)
      api_render @async_job
    end
  end


  # POST /async_jobs
  def create
    ActionController::Parameters.permit_all_parameters = true
    @async_job = AsyncJob.new(params)
    if @async_job.steps == []
      @async_job.started_at = Time.now.utc
      @async_job.finished_at = @async_job.started_at
    end
    set_updater(@async_job)
    @async_job.save!
    api_render @async_job, new: true
  end


  # DELETE /async_jobs/1
  def destroy
    @async_job.destroy
    render_head_204
  end
  
  
  private
     
  def find_async_job
    ActionController::Parameters.permit_all_parameters = true
    the_id = params['uuid'] || params['id']  # 'id' when received from the Rails router, uuid othw
    # The following song and dance because we don't have AsyncJob.find_by_id()
    begin 
      @async_job = (AsyncJob.find(the_id, consistent: true))
    rescue OceanDynamo::RecordNotFound
      @async_job = nil
    end
    # End of song and dance
    return true if @async_job
    render_api_error 404, "AsyncJob not found"
    false
  end
    
end

