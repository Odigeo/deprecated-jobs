class TheModel < ActiveRecord::Base

  ocean_resource_model index: [:name], 
                       search: :description,
                       invalidate_member:     INVALIDATE_MEMBER_DEFAULT + [lambda { |m| "foo/bar/baz($|?)" }],
                       invalidate_collection: INVALIDATE_COLLECTION_DEFAULT

  attr_accessible :name, :description, :lock_version

  validates :name, length: { minimum: 3 }

end
