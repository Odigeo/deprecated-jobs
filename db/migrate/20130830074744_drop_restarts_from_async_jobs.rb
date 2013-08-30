class DropRestartsFromAsyncJobs < ActiveRecord::Migration

  def change
    remove_column :async_jobs, :restarts, :integer, default: 0, null: false
  end

end
