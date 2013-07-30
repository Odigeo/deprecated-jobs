class AddCredentialsToAsyncJob < ActiveRecord::Migration

  def change
    add_column :async_jobs, :credentials, :string, null: false, default: ''
  end

end
