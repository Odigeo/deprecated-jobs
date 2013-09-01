class AddDeleteAtIndexToAsyncJobs < ActiveRecord::Migration
  def change
    add_index :async_jobs, :destroy_at
  end
end
