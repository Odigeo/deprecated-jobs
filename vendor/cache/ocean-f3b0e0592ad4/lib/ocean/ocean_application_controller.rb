module OceanApplicationController


  def default_url_options(options = nil)
    # We should ALWAYS generate external URIs, even for internal calls.
    # It's the responsibility of the other service to rewrite external
    # to internal URIs when calling the internal API point.
    { :protocol => "https", :host => OCEAN_API_HOST }
  end
  
  
  #
  # X-API-Token processing
  #
  def require_x_api_token
    return true if ENV['NO_OCEAN_AUTH']
    @x_api_token = request.headers['X-API-Token']
    return true if @x_api_token.present?
    logger.info "X-API-Token missing"
    render_api_error 400, "X-API-Token missing"
    false
  end
  


  #
  # Authorization
  #
  @@extra_actions = {}

  def authorize_action
    return true if ENV['NO_OCEAN_AUTH']
    # Obtain any nonstandard actions
    @@extra_actions[controller_name] ||= begin
      extra_actions
    rescue NameError => e
      {}
    end
    # Create a query string and call Auth
    qs = Api.authorization_string(@@extra_actions, controller_name, action_name)
    response = Api.permitted?(@x_api_token, query: qs)                                   
    if response.status == 200
      @auth_api_user_id = response.body['authentication']['user_id']
      return true
    end
    error_messages = response.body['_api_error']
    render_api_error response.status, *error_messages
    false
  end

  
  #
  # Updating created_by and updated_by
  #
  def set_updater(obj)
    obj.created_by = @auth_api_user_id if obj.created_by.blank? || obj.created_by == 0
    obj.updated_by = @auth_api_user_id
  end
  
  
  #
  # JSON renderers
  #
  def render_api_error(status_code, *message)
    render json: {_api_error: [*message]}, status: status_code
  end
  
  def render_head_204
    render text: '', status: 204, content_type: 'application/json'
  end
  
  def render_validation_errors(r)
    render json: r.errors, :status => 422
  end
  
  def render_new_resource(r, partial: nil)
    if partial
      render partial: partial, object: r, :status => 201, :location => r
    else
      render r, :status => 201, :location => r
    end
  end
  
  
  #
  # Filtering away all non-accessible attributes from params
  #
  def filtered_params(klass)
    result = {}
    params.each do |k, v| 
      result[k] = v if klass.accessible_attributes.include?(k)
    end
    result
  end


  #
  # Cache values for collectives. Accepts a class or a scope.
  #
  def collection_etag(coll)
    coll.name.constantize # Force a load of the class (for secondary collections)
    last_updated = coll.order(:updated_at).last.updated_at.utc rescue 0
    # We could also, in the absence of an updated_at attribute, use created_at.
    { etag: "#{coll.name}:#{coll.count}:#{last_updated}"
    }
  end


  #
  # Finding the other resource for connect/disconnect
  #
  def find_connectee
    href = params[:href]
    render_api_error(422, "href query arg is missing") and return if href.blank?
    begin
      routing = Rails.application.routes.recognize_path(href)
    rescue ActionController::RoutingError
      render_api_error(422, "href query arg isn't parseable")
      return
    end
    @connectee_class = routing[:controller].classify.constantize
    @connectee = @connectee_class.find_by_id(routing[:id])
    render_api_error(404, "Resource to connect not found") and return unless @connectee
    true
  end

end
