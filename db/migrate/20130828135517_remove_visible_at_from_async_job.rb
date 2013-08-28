class RemoveVisibleAtFromAsyncJob < ActiveRecord::Migration

  def change
    remove_column :async_jobs, :visible_at, :datetime
  end

end
