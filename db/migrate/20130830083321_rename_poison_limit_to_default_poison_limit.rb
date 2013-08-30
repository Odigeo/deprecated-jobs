class RenamePoisonLimitToDefaultPoisonLimit < ActiveRecord::Migration

  def change
    rename_column :async_jobs, :poison_limit, :default_poison_limit
  end

end
