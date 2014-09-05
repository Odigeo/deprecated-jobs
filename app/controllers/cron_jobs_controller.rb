class CronJobsController < ApplicationController

  ocean_resource_controller required_attributes: [:lock_version]  # PUT isn't used: no required args

  # The following params are required:
  #   :credentials
  # The following params are permitted:
  #   :token, :steps, :max_seconds_in_queue, :default_poison_limit, default_step_time


  respond_to :json
  
  before_action :find_cron_job, :only => [:show, :update, :destroy]
    

  # GET /cron_jobs
  def index
  end


  # POST /cron_jobs
  def create
  end


  # GET /cron_jobs/1
  def show
  end


  # PUT /cron_jobs/1
  def update
  end


  # DELETE /cron_jobs/1
  def destroy
  end
  
  
  private
     
  def find_async_job
    ActionController::Parameters.permit_all_parameters = true
    the_id = params['uuid'] || params['id']  # 'id' when received from the Rails router, uuid othw
    @cron_job = CronJob.find_by_key(the_id, consistent: true)

    return true if @cron_job
    render_api_error 404, "CronJob not found"
    false
  end
    
end

