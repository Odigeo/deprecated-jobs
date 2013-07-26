class AddInvisibleUntilToAsyncJob < ActiveRecord::Migration

  def change
    add_column :async_jobs, :invisible_until, :datetime
  end
  
end
