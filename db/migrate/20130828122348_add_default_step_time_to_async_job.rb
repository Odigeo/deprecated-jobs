class AddDefaultStepTimeToAsyncJob < ActiveRecord::Migration

  def change
    add_column :async_jobs, :default_step_time, :integer, null:false, default: 30
  end

end
