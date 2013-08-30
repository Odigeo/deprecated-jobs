class AddBooleansToAsyncJob < ActiveRecord::Migration
  def change
    add_column :async_jobs, :succeeded, :boolean, null: false, default: false
    add_column :async_jobs, :failed,    :boolean, null: false, default: false
    add_column :async_jobs, :poison,    :boolean, null: false, default: false
  end
end
