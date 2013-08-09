#
# We need to monkey-patch Faraday to pull off PURGE and BAN
#
require 'faraday'
require 'faraday_middleware'

module Faraday
  class Connection

    METHODS << :purge
    METHODS << :ban

    # purge/ban(url, params, headers)
    %w[purge ban].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url = nil, params = nil, headers = nil)
          run_request(:#{method}, url, nil, headers) { |request|
            request.params.update(params) if params
            yield request if block_given?
          }
        end
      RUBY
    end

  end
end


#
# This class encapsulates the logic for calling other API services.
#

class Api
  
  def self.version_for(resource_name)
    API_VERSIONS[resource_name.to_s] || API_VERSIONS['_default']
  end
  
  def self.token
    @token
  end
      
  
  def self.call(url, http_method, service_name, path, args={}, headers={})
    # Set up the connection parameters
    conn = Faraday.new(url) do |c|
      c.response :json, :content_type => /\bjson$/    # Convert the response body to JSON
      c.adapter Faraday.default_adapter               # Use net-http
    end
    api_version = version_for service_name
    path = "/#{api_version}#{path}"
    # Make the call. TODO: retries?
    response = conn.send(http_method, path, args, headers) do |request|
      request.headers['Accept'] = 'application/json'
      request.headers['Content-Type'] = 'application/json'
    end
    response
  end
  
  def self.get(*args)    call(INTERNAL_OCEAN_API_URL, :get, *args);    end
  def self.post(*args)   call(INTERNAL_OCEAN_API_URL, :post, *args);   end
  def self.put(*args)    call(INTERNAL_OCEAN_API_URL, :put, *args);    end
  def self.delete(*args) call(INTERNAL_OCEAN_API_URL, :delete, *args); end


  # TODO: do the following in parallel
  def self.call_p(url, http_method, path, args={}, headers={})
    conn = Faraday.new(url) do |c|
      c.adapter Faraday.default_adapter               # Use net-http
    end
    conn.send(http_method, path, args, headers)
  end

  def self.purge(*args)  
    LOAD_BALANCERS.each do |host| 
      call_p("http://#{host}", :purge, *args)
    end
  end

  def self.ban(path)     
    LOAD_BALANCERS.each do |host| 
      call_p("http://#{host}", :ban, path)
    end
  end

  
  def self.authenticate(username=API_USER, password=API_PASSWORD)
    response = Api.post(:auth, "/authentications", nil, 
                               {'X-API-Authenticate' => encode_credentials(username, password)})
    case response.status
    when 201
      @token = response.body['authentication']['token']
    when 400
      # Malformed credentials. Don't repeat the request.
      nil
    when 403
      # Does not authenticate. Don't repeat the request.
      nil 
    when 500
      # Error. Don't repeat. 
      nil   
    else
      # Should never end up here.
      raise "Authentication weirdness"
    end
  end
  
  def self.encode_credentials(username, password)
    ::Base64.strict_encode64 "#{username}:#{password}"
  end
  
  def self.decode_credentials(encoded)
    return ["", ""] unless encoded
    username, password = ::Base64.decode64(encoded).split(':', 2)
    [username || "", password || ""]
  end
  
  
  def self.permitted?(token, args={})
    raise unless token
    #response = Api.get(:auth, "/authentications/#{token}", args, {'X-API-Token' => token})
    response = Api.get(:auth, "/authentications/#{token}", args)
    response
  end  


  def self.authorization_string(extra_actions, controller, action, app="*", context="*", service=APP_NAME)
    app = '*' if app.blank?
    context = '*' if context.blank?
    hyperlink, verb = Api.map_authorization(extra_actions, controller, action)
    "#{service}:#{controller}:#{hyperlink}:#{verb}:#{app}:#{context}"
  end


  DEFAULT_ACTIONS = {
    'show' =>    ['self', 'GET'],
    'index' =>   ['self', 'GET*'],
    'create' =>  ['self', 'POST'],
    'update' =>  ['self', 'PUT'],
    'destroy' => ['self', 'DELETE'],
    'connect' =>    ['connect', 'PUT'],
    'disconnect' => ['connect', 'DELETE']
  }

  def self.map_authorization(extra_actions, controller, action)
    DEFAULT_ACTIONS[action] ||
    extra_actions[controller][action] ||
    raise #"The #{controller} lacks an extra_action declaration for #{action}"
  end


end
