json.<%= singular_name %> do |json|
	json._links       hyperlinks(self:    <%= singular_name %>_url(<%= singular_name %>),
	                             creator: api_user_url(id: <%= singular_name %>.created_by || 0),
	                             updater: api_user_url(id: <%= singular_name %>.updated_by || 0))
	json.(<%= singular_name %>, :lock_version) 
	json.created_at   <%= singular_name %>.created_at.utc.iso8601
	json.updated_at   <%= singular_name %>.updated_at.utc.iso8601
end
