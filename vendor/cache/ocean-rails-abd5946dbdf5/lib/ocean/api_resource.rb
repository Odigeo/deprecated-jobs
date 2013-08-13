module ApiResource

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    #
    # This method implements the common behaviour in Ocean for requesting collections
    # of resources, including conditions, +GROUP+ and substring searches. It can be used
    # directly on a class:
    #
    #  @collection = ApiUser.collection(params)
    #
    # or on any Relation:
    #
    #  @collection = @api_user.groups.collection(params)
    #
    # Since a Relation is returned, further chaining is possible:
    #
    #  @collection = @api_user.groups.collection(params).active.order("email ASC")
    #
    # The whole params hash can safely be passed as the input arg: keys are filtered so 
    # that matches only are done against the attributes declared in the controller using 
    # +ocean_resource_model+.
    #
    # The +group:+ keyword arg, if present, adds a +GROUP+ clause to the generated SQL.
    #
    # The +search:+ keyword arg, if present, searches for the value in the database string or
    # text column declared in the controller's +ocean_resource_model+ declaration.
    # The search is done using an SQL +LIKE+ clause, with the substring framed by 
    # wildcard characters. It's self-evident that this is not an efficient search method
    # for larger datasets; in such cases, other search methods should be employed.
    #
    # If +page:+ is present, pagination will be added. If +page+ is less than zero, an
    # empty Relation will be returned. Otherwise, +page_size:+ (default 25) will be used
    # to calculate OFFSET and LIMIT. The default +page_size+ for a resource class can
    # also be declared using +ocean_resource_model+.
    #
    def collection(bag={})
      collection_internal bag, bag[:group], bag[:search], bag[:page], bag[:page_size]
    end


    def collection_internal(conds={}, group, search, page, page_size)
      if index_only != []
        new_conds = {}
        index_only.each { |key| new_conds[key] = conds[key] if conds[key].present? }
        conds = new_conds
      end
      # Fold in the conditions
      query = all.where(conds)
      # Take care of grouping
      query = query.group(group) if group.present? && index_only.include?(group.to_sym)
      # Searching
      if search.present?
        return query.none if index_search_property.blank?
        query = query.where("#{index_search_property} LIKE ?", "%#{search}%")
      end
      # Pagination
      if page.present?
        return query.none if page < 0
        query = query.limit(page_size || collection_page_size).offset(page_size * page)
      end
      # Finally, return the accumulated Relation
      query
    end


    #
    # Returns the latest version for the resource class. E.g.:
    #
    #  > ApiUser.latest_version
    #  "v1"
    #
    def latest_api_version
      Api.version_for(self.class.name.pluralize.underscore)
    end

    #
    # Invalidate all members of this class in Varnish using a +BAN+ requests to all
    # caches in the Chef environment. The +BAN+ requests are done in parallel.
    # The number of +BAN+ requests, and the exact +URI+ composition in each request,
    # is determined by the +invalidate_collection:+ arg to the +ocean_resource_model+
    # declaration in the model.
    #
    def invalidate
      resource_name = name.pluralize.underscore
      varnish_invalidate_collection.each do |suffix|
        Api.ban "/v[0-9]+/#{resource_name}#{suffix}"
      end
    end

  end


  # Instance methods

  #
  # Convenience function used to touch two resources in one call, e.g:
  #
  #  @api_user.touch_both(@connectee)
  #
  def touch_both(other)
    touch
    other.touch
  end


  #
  # Invalidate the member and all its collections in Varnish using a +BAN+ requests to all
  # caches in the Chef environment. The +BAN+ request are done in parallel.
  # The number of +BAN+ requests, and the exact +URI+ composition in each request,
  # is determined by the +invalidate_member:+ arg to the +ocean_resource_model+
  # declaration in the model.
  #
  # The optional arg +avoid_self+, if true (the default is false), avoids invalidating
  # the basic resource itself: only its derived collections are invalidated. This is useful
  # when instantiating a new resource.
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
