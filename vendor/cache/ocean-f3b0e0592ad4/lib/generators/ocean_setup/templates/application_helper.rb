module ApplicationHelper

  #
  # Used in Jbuilder templates to build hyperlinks
  #
  def hyperlinks(links={})
    result = {}
    links.each do |qi, val|
      result[qi.to_s] = { 
                 "href" => val.kind_of?(String) ? val : val[:href], 
                 "type" => val.kind_of?(String) ? "application/json" : val[:type]
              }
    end
    result
  end
  

  #
  # This is needed everywhere except inside the Auth service to render creator
  # and updater links correctly.
  #
  def api_user_url(api_user_id)
    "#{OCEAN_API_URL}/#{Api.version_for :api_user}/api_users/#{api_user_id || 0}"
  end

end
