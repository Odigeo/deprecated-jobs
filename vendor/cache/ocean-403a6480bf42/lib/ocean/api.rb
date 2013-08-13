#
# We need to monkey-patch Faraday to pull off PURGE and BAN
#
require 'faraday'
require 'faraday_middleware'

module Faraday #:nodoc: all
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
# This class encapsulates all logic for calling other API services.
#
class Api
  
  #
  # When given a symbol or string naming a resource, returns a string 
  # such as +v1+ naming the latest version for the resource.
  #
  def self.version_for(resource_name)
    API_VERSIONS[resource_name.to_s] || API_VERSIONS['_default']
  end
  
  #
  # Given that this service has authenticated successfully with the Auth service,
  # returns the token returned as part of the authentication response.
  #
  def self.token
    @token
  end
      
  
  #
  # Makes a HTTP request to +host_url+ using the HTTP method +method+. The +resource_name+
  # is used to obtain the latest version string of the resource. The arg +path+ is the
  # local path, +args+ is a hash of query args, and +headers+ a hash of extra HTTP headers.
  #
  # Returns the response in its entirety so that the caller can examine its status and body.
  #
  def self.call(host_url, http_method, resource_name, path, args={}, headers={})
    # Set up the connection parameters
    conn = Faraday.new(host_url) do |c|
      c.response :json, :content_type => /\bjson$/    # Convert the response body to JSON
      c.adapter Faraday.default_adapter               # Use net-http
    end
    api_version = version_for resource_name
    path = "/#{api_version}#{path}"
    # Make the call. TODO: retries?
    response = conn.send(http_method, path, args, headers) do |request|
      request.headers['Accept'] = 'application/json'
      request.headers['Content-Type'] = 'application/json'
    end
    response
  end
  
  #
  # Convenience method to make an internal GET request to the Ocean Api. The +resource_name+
  # is used to obtain the latest version string of the resource. The arg +path+ is the
  # local path, +args+ is a hash of query args, and +headers+ a hash of extra HTTP headers.
  #
  # Returns the response in its entirety so that the caller can examine its status and body.
  #
  #
  def self.get(*args)    call(INTERNAL_OCEAN_API_URL, :get, *args);    end

  #
  # Convenience method to make an internal POST request to the Ocean Api. The +resource_name+
  # is used to obtain the latest version string of the resource. The arg +path+ is the
  # local path, +args+ is a hash of query args, and +headers+ a hash of extra HTTP headers.
  #
  # Returns the response in its entirety so that the caller can examine its status and body.
  #
  #
  def self.post(*args)   call(INTERNAL_OCEAN_API_URL, :post, *args);   end

  #
  # Convenience method to make an internal PUT request to the Ocean Api. The +resource_name+
  # is used to obtain the latest version string of the resource. The arg +path+ is the
  # local path, +args+ is a hash of query args, and +headers+ a hash of extra HTTP headers.
  #
  # Returns the response in its entirety so that the caller can examine its status and body.
  #
  #
  def self.put(*args)    call(INTERNAL_OCEAN_API_URL, :put, *args);    end

  #
  # Convenience method to make an internal DELETE request to the Ocean Api. The +resource_name+
  # is used to obtain the latest version string of the resource. The arg +path+ is the
  # local path, +args+ is a hash of query args, and +headers+ a hash of extra HTTP headers.
  #
  # Returns the response in its entirety so that the caller can examine its status and body.
  #
  #
  def self.delete(*args) call(INTERNAL_OCEAN_API_URL, :delete, *args); end


  #
  # Like Api.call, but makes the requests in parallel. (Parallel calls not implemented yet.)
  #
  def self.call_p(url, http_method, path, args={}, headers={})
    conn = Faraday.new(url) do |c|
      c.adapter Faraday.default_adapter               # Use net-http
    end
    conn.send(http_method, path, args, headers)
  end

  #
  # Makes an internal PURGE call to all Varnish instances. The call is made in parallel.
  # Varnish will only accept PURGE requests coming from the local network.
  #
  def self.purge(*args)  
    LOAD_BALANCERS.each do |host| 
      call_p("http://#{host}", :purge, *args)
    end
  end

  #
  # Makes an internal BAN call to all Varnish instances. The call is made in parallel.
  # Varnish will only accept PURGE requests coming from the local network.
  #
  def self.ban(path)     
    LOAD_BALANCERS.each do |host| 
      call_p("http://#{host}", :ban, path)
    end
  end

  
  #
  # Authenticates against the Auth service (which must be deployed and running) with
  # a given +username+ and +password+. If successful, the authentication token is returned. The
  # token is also assigned to the instance variable @token. If not successful, +nil+ is returned.
  #
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
  

  #
  # Encodes a username and password for authentication in the format used for standard HTTP 
  # authentication. The encoding can be reversed and is intended only to lightly mask the
  # credentials so that they're not immediately apparent when reading logs.
  #
  def self.encode_credentials(username, password)
    ::Base64.strict_encode64 "#{username}:#{password}"
  end
  
  #
  # Takes encoded credentials (e.g. by Api.encode_credentials) and returns a two-element array
  # where the first element is the username and the second is the password. If the encoded
  # credentials are missing or can't be decoded properly, ["", ""] is returned. This allows
  # you to write:
  #   
  #   un, pw = Api.decode_credentials(creds)
  #   raise "Please supply your username and password" if un.blank? || pw.blank?
  #
  def self.decode_credentials(encoded)
    return ["", ""] unless encoded
    username, password = ::Base64.decode64(encoded).split(':', 2)
    [username || "", password || ""]
  end
  
  #
  # Performs authorisation against the Auth service. The +token+ must be a token received as a 
  # result of a prior authentication operation. The args should be in the form
  #
  #   query: "service:controller:hyperlink:verb:app:context"
  #
  # e.g.
  #
  #   Api.permitted?(@token, query: "cms:texts:self:GET:*:*")
  #
  # Api.authorization_string can be used to produce the query string.
  # 
  # Returns the HTTP response as-is, allowing the caller to examine the status code and
  # messages, and also the body.
  #
  def self.permitted?(token, args={})
    raise unless token
    response = Api.get(:auth, "/authentications/#{token}", args)
    response
  end  


  #
  # Returns an authorisation string suitable for use in calls to Api.permitted?. 
  # The +extra_actions+ arg holds the extra actions as defined in the Ocean controller; it must
  # be included here so that actions can be mapped to the proper hyperlink and verb.
  # The +controller+ and +action+ args are mandatory. The +app+ and +context+ args are optional and will
  # default to "*". The last arg, +service+, defaults to the name of the service itself.
  #
  def self.authorization_string(extra_actions, controller, action, app="*", context="*", service=APP_NAME)
    app = '*' if app.blank?
    context = '*' if context.blank?
    hyperlink, verb = Api.map_authorization(extra_actions, controller, action)
    "#{service}:#{controller}:#{hyperlink}:#{verb}:#{app}:#{context}"
  end


  #
  # These are the default controller actions. The purpose of this constant is to map action
  # names to hyperlink and HTTP method (for authorisation purposes). Don't be alarmed by the
  # non-standard GET* - it's purely symbolic and is never used as an actual HTTP method. 
  # We need it to differentiate between a GET of a member and a GET of a collection of members. 
  # The +extra_actions+ keyword in +ocean_resource_controller+ follows the same format.
  #
  DEFAULT_ACTIONS = {
    'show' =>    ['self', 'GET'],
    'index' =>   ['self', 'GET*'],
    'create' =>  ['self', 'POST'],
    'update' =>  ['self', 'PUT'],
    'destroy' => ['self', 'DELETE'],
    'connect' =>    ['connect', 'PUT'],
    'disconnect' => ['connect', 'DELETE']
  }

  #
  # Returns the hyperlink and HTTP method to use for an +action+ in a certain +controller+.
  # First, the +DEFAULT_ACTIONS+ are searched, then any extra actions defined for the
  # controller. Raises an exception if the action can't be found.
  #
  def self.map_authorization(extra_actions, controller, action)
    DEFAULT_ACTIONS[action] ||
    extra_actions[controller][action] ||
    raise #"The #{controller} lacks an extra_action declaration for #{action}"
  end


end
