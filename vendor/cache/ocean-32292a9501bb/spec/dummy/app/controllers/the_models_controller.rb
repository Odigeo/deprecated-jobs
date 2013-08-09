class TheModelsController < ApplicationController

  ocean_resource_controller extra_actions: {},
                            required_attributes: [:lock_version, :name, :description]

  respond_to :json
  
  before_action :find_the_model, :only => [:show, :update, :destroy]
    
  
  # GET /v1/the_models
  def index
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(collection_etag(TheModel))
      the_models = TheModel.index(params, params[:group], params[:search])
      api_render the_models
    end
  end


  # GET /v1/the_models/1
  def show
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(@the_model)
      api_render @the_model
    end
  end


  # POST /v1/the_models
  def create
    @the_model = TheModel.new(filtered_params TheModel)
    set_updater(@the_model)
    if @the_model.valid?
      begin
        @the_model.save!
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid, 
             SQLite3::ConstraintException 
        render_api_error 422, "TheModel already exists"
        return
      end
      api_render @the_model, new: true
    else
      render_validation_errors @the_model
    end
  end


  # PUT /v1/the_models/1
  def update
    if missing_attributes?
      render_api_error 422, "Missing resource attributes"
      return
    end
    begin
      @the_model.assign_attributes(filtered_params TheModel)
      set_updater(@the_model)
      @the_model.save
    rescue ActiveRecord::StaleObjectError
      render_api_error 409, "Stale TheModel"
      return
    end
    if @the_model.valid?
      api_render @the_model
    else
      render_validation_errors(@the_model)
    end
  end


  # DELETE /v1/the_models/1
  def destroy
    @the_model.destroy
    render_head_204
  end
  
  
  private
     
  def find_the_model
    @the_model = TheModel.find_by_id params[:id]
    return true if @the_model
    render_api_error 404, "TheModel not found"
    false
  end
    
end
