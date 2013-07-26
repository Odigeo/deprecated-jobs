class AddPoisonLimitToAsyncJob < ActiveRecord::Migration

  def change
    add_column :async_jobs, :poison_limit, :integer, null: false, default: 5
  end
  
end
