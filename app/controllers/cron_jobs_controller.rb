class CronJobsController < ApplicationController

  ocean_resource_controller required_attributes: [:lock_version, :steps, :cron],
                            extra_actions: { 'execute' => ['execute', "PUT"],
                                             'run'     => ['run',     "PUT"]}

  # The following params are required:
  #   :credentials
  # The following params are permitted:
  #   :token, :steps, :max_seconds_in_queue, :default_poison_limit, default_step_time,
  #   :poison_email, :enabled


  respond_to :json

  skip_before_filter :require_x_api_token, only: :execute
  skip_before_filter :authorize_action, only: :execute

  
  before_action :find_cron_job, :only => [:show, :update, :destroy, :run]
    

  # GET /cron_jobs
  def index
    expires_in 0, 's-maxage' => 3.hours
    # if stale?(collection_etag(CronJob))   # collection_etag is still ActiveRecord only!
    # Instead, we get all the CronJobs (they are few) and compute the ETag manually:
    @cron_jobs = CronJob.all    
    latest = @cron_jobs.max_by(&:updated_at)
    last_updated = latest && latest.updated_at 
    if stale?(etag: "CronJob:#{CronJob.count}:#{last_updated}")
      api_render @cron_jobs
    end
  end


  # POST /cron_jobs
  def create
    ActionController::Parameters.permit_all_parameters = true
    @cron_job = CronJob.new(params)
    set_updater(@cron_job)
    @cron_job.save!
    api_render @cron_job, new: true
  end


  # GET /cron_jobs/a-b-c-d-e
  def show
    expires_in 0, 's-maxage' => 3.hours
    if stale?(etag: @cron_job.lock_version,          # NB: DynamoDB tables dont have cache_key - FIX!
              last_modified: @cron_job.updated_at)
      api_render @cron_job
    end
  end


  # PUT /cron_jobs/a-b-c-d-e
  def update
    if missing_attributes?
      render_api_error 422, "Missing resource attributes"
      return
    end
    @cron_job.assign_attributes(steps: params[:steps], 
                                name: params[:name],
                                description: params[:description],
                                credentials: params[:credentials],
                                max_seconds_in_queue: params[:max_seconds_in_queue],
                                default_poison_limit: params[:default_poison_limit],
                                default_step_time: params[:default_step_time],
                                cron: params[:cron],
                                enabled: params[:enabled],
                                lock_version: params[:lock_version],
                                poison_email: params[:poison_email]
                               )
    set_updater(@cron_job)
    @cron_job.save!
    api_render @cron_job
  end


  # DELETE /cron_jobs/a-b-c-d-e
  def destroy
    @cron_job.destroy
    render_head_204
  end


  # PUT /cron_jobs/a-b-c-d-e/run
  def run
    @cron_job.last_async_job_id = @cron_job.post_async_job
    @cron_job.save!
    render_head_204
  end


  # PUT /execute_cron_jobs
  def execute
    CronJob.process_queue
    render_head_204
  end
  
  
  private
     
  def find_cron_job
    ActionController::Parameters.permit_all_parameters = true
    the_id = params['uuid'] || params['id']  # 'id' when received from the Rails router, uuid othw
    @cron_job = CronJob.find_by_key(the_id, consistent: true)
    return true if @cron_job
    render_api_error 404, "CronJob not found"
    false
  end
    
end

