class AddMaxSecondsInQueueAndDestroyAtToAsyncJobs < ActiveRecord::Migration

  def change
    add_column :async_jobs, :max_seconds_in_queue, :integer, null: false, default: 1.day
    add_column :async_jobs, :destroy_at, :datetime
  end
  
end
