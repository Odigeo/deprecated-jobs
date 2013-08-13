json.<%= singular_name %> do |json|
	json._links       hyperlinks(self:    <%= singular_name %>_url(<%= singular_name %>),
	                             creator: <%= singular_name %>.created_by || api_user_url(0),
	                             updater: <%= singular_name %>.updated_by || api_user_url(0))
	json.(<%= singular_name %>, :lock_version, :name, :description) 
	json.created_at   <%= singular_name %>.created_at.utc.iso8601
	json.updated_at   <%= singular_name %>.updated_at.utc.iso8601
end
