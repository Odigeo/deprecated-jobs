class RemoveStateFromAsyncJob < ActiveRecord::Migration
  def change
    remove_column :async_jobs, :state, :string, null: false, default: ""
  end
end
