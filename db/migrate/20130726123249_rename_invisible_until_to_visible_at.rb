class RenameInvisibleUntilToVisibleAt < ActiveRecord::Migration
  def change
    remove_column :async_jobs, :invisible_until, :datetime
    add_column    :async_jobs, :visible_at, :datetime
  end
end
