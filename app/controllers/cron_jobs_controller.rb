class CronJobsController < ApplicationController

  ocean_resource_controller required_attributes: [:lock_version, :steps, :cron],
                            extra_actions: { 'execute' => ['execute', "PUT"]}

  # The following params are required:
  #   :credentials
  # The following params are permitted:
  #   :token, :steps, :max_seconds_in_queue, :default_poison_limit, default_step_time


  respond_to :json

  skip_before_filter :require_x_api_token, only: :execute
  skip_before_filter :authorize_action, only: :execute

  
  before_action :find_cron_job, :only => [:show, :update, :destroy]
    

  # GET /cron_jobs
  def index
    # expires_in 0, 's-maxage' => 30.minutes
    # if stale?(collection_etag(CronJob))   # collection_etag is still ActiveRecord only!
      @cron_jobs = CronJob.all.reject { |job| job.id == CronJob::TABLE_LOCK_RECORD_ID }
      api_render @cron_jobs
    # end
  end


  # POST /cron_jobs
  def create
    render_api_error 422, "ID is illegal" and return if params[:id] == CronJob::TABLE_LOCK_RECORD_ID
    ActionController::Parameters.permit_all_parameters = true
    @cron_job = CronJob.new(params)
    set_updater(@cron_job)
    @cron_job.save!
    api_render @cron_job, new: true
  end


  # GET /cron_jobs/1
  def show
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(etag: @cron_job.lock_version,          # NB: DynamoDB tables dont have cache_key - FIX!
              last_modified: @cron_job.updated_at)
      api_render @cron_job
    end
  end


  # PUT /cron_jobs/1
  def update
    if missing_attributes?
      render_api_error 422, "Missing resource attributes"
      return
    end
    @cron_job.assign_attributes(steps: params[:steps], 
                                name: params[:name],
                                description: params[:description],
                                credentials: params[:credentials],
                                token: params[:token],
                                max_seconds_in_queue: params[:max_seconds_in_queue],
                                default_poison_limit: params[:default_poison_limit],
                                default_step_time: params[:default_step_time],
                                cron: params[:cron],
                                enabled: params[:enabled],
                                lock_version: params[:lock_version]
                               )
    set_updater(@cron_job)
    @cron_job.save!
    api_render @cron_job
  end


  # DELETE /cron_jobs/1
  def destroy
    @cron_job.destroy
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
    @cron_job = the_id != CronJob::TABLE_LOCK_RECORD_ID &&
                CronJob.find_by_key(the_id, consistent: true)
    return true if @cron_job
    render_api_error 404, "CronJob not found"
    false
  end
    
end

