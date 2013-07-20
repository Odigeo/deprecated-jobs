class CreateAsyncJobs < ActiveRecord::Migration
  def change
    create_table :async_jobs do |t|
      t.string   :uuid,          null: false
      t.integer  :restarts,      null: false, default: 0
      t.string   :state,         null: false, default: ""
      t.datetime :started_at,    null: true,  default: nil
      t.datetime :finished_at,   null: true,  default: nil
      t.text     :payload
      t.integer  :lock_version,  null: false, default: 0
      t.integer  :created_by,    null: false, default: 0
      t.integer  :updated_by,    null: false, default: 0

      t.timestamps
    end

    add_index :async_jobs, :uuid, unique: true
  end
end
