class AddLastCompletedStepToAsyncJobs < ActiveRecord::Migration

  def change
    add_column :async_jobs, :last_completed_step, :integer
  end
  
end
