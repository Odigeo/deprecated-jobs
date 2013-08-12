class AsyncJobsController < ApplicationController

  ocean_resource_controller extra_actions: {},
                            required_attributes: []  # PUT isn't used: no required args

  respond_to :json
  
  before_action :find_async_job, :only => [:show, :destroy]
    
  
  # GET /async_jobs
  def index
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(collection_etag(AsyncJob))
      api_render AsyncJob.collection(params)
    end
  end


  # GET /async_jobs/1
  def show
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(@async_job)
      api_render @async_job
    end
  end


  # POST /async_jobs
  def create
    @async_job = AsyncJob.new(filtered_params AsyncJob)
    set_updater(@async_job)
    if @async_job.valid?
      begin
        if @async_job.steps == []
          @async_job.started_at = Time.now.utc
          @async_job.finished_at = @async_job.started_at
        end
        @async_job.save!
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid, 
             SQLite3::ConstraintException 
        render_api_error 422, "AsyncJob already exists"
        return
      end
      api_render @async_job, new: true
    else
      render_validation_errors @async_job
    end
  end


  # DELETE /async_jobs/1
  def destroy
    @async_job.destroy
    render_head_204
  end
  
  
  private
     
  def find_async_job
    the_id = params['uuid'] || params['id']  # 'id' when received from the Rails router, uuid othw
    @async_job = AsyncJob.find_by_uuid the_id
    return true if @async_job
    render_api_error 404, "AsyncJob not found"
    false
  end
    
end
