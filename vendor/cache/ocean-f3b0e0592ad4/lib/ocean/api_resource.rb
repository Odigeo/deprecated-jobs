module ApiResource

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    #
    # The whole params hash can safely be passed in as the first arg: the 
    # index_only class method is used to filter away disallowed record attributes.
    #
    def index(conds={}, group_by=nil, substring=nil)
      # TODO: pagination
      if index_only != []
        new_conds = {}
        index_only.each { |key| new_conds[key] = conds[key] if conds[key].present? }
        conds = new_conds
      end
      query = all.where(conds)
      query = query.group(group_by) if group_by.present? && index_only.include?(group_by.to_sym)
      query = query.where("#{index_search_property} LIKE ?", "%#{substring}%") if substring
      query
    end
    

    #
    # Returns the latest version for the resource
    #
    def latest_api_version
      Api.version_for(self.class.name.pluralize.underscore)
    end

    #
    # Invalidate all members of this class in Varnish
    #
    def invalidate
      resource_name = name.pluralize.underscore
      varnish_invalidate_collection.each do |suffix|
        Api.ban "/v[0-9]+/#{resource_name}#{suffix}"
      end
    end

  end


  # Instance methods

  def touch_both(other)
    touch
    other.touch
  end


  #
  # Invalidate the member and all its collections in Varnish
  #
  def invalidate(avoid_self=false)
    self.class.invalidate
    resource_name = self.class.name.pluralize.underscore
    varnish_invalidate_member.each do |thing|
      if thing.is_a?(String)
        Api.ban "/v[0-9]+/#{resource_name}/#{self.id}#{thing}" if !avoid_self
      else
        Api.ban "/v[0-9]+/#{thing.call(self)}"
      end
    end
  end

end
