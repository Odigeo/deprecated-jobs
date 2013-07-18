<% if namespaced? -%>
require_dependency "<%= namespaced_file_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController

  ocean_resource_controller extra_actions: {},
                            required_attributes: [:lock_version, :name, :description]

  respond_to :json
  
  before_action :find_<%= singular_table_name %>, :only => [:show, :update, :destroy]
    
  
  # GET <%= route_url %>
  def index
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(collection_etag(<%= class_name %>))
      @<%= plural_table_name %> = <%= class_name %>.index(params, params[:group], params[:search])
      render partial: "<%= singular_table_name %>", collection: @<%= plural_table_name %>
    end
  end


  # GET <%= route_url %>/1
  def show
    expires_in 0, 's-maxage' => 30.minutes
    if stale?(@<%= singular_table_name %>)
      render partial: "<%= singular_table_name %>", object: @<%= singular_table_name %>
    end
  end


  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= class_name %>.new(filtered_params <%= class_name %>)
    set_updater(@<%= singular_table_name %>)
    if @<%= singular_table_name %>.valid?
      begin
        @<%= singular_table_name %>.save!
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid, 
             SQLite3::ConstraintException 
        render_api_error 422, "<%= class_name %> already exists"
        return
      end
      render_new_resource @<%= singular_table_name %>, partial: "<%= plural_table_name %>/<%= singular_table_name %>"
    else
      render_validation_errors @<%= singular_table_name %>
    end
  end


  # PUT <%= route_url %>/1
  def update
    if missing_attributes?
      render_api_error 422, "Missing resource attributes"
      return
    end
    begin
      @<%= singular_table_name %>.assign_attributes(filtered_params <%= class_name %>)
      set_updater(@<%= singular_table_name %>)
      @<%= singular_table_name %>.save
    rescue ActiveRecord::StaleObjectError
      render_api_error 409, "Stale <%= class_name %>"
      return
    end
    if @<%= singular_table_name %>.valid?
      render partial: "<%= singular_table_name %>", object: @<%= singular_table_name %>
    else
      render_validation_errors(@<%= singular_table_name %>)
    end
  end


  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>
    render_head_204
  end
  
  
  private
     
  def find_<%= singular_table_name %>
    @<%= singular_table_name %> = <%= class_name %>.find_by_id params[:id]
    return true if @<%= singular_table_name %>
    render_api_error 404, "<%= class_name %> not found"
    false
  end
    
end
<% end -%>
