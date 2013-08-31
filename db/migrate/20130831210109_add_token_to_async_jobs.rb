class AddTokenToAsyncJobs < ActiveRecord::Migration
  def change
    add_column :async_jobs, :token, :string
  end
end
