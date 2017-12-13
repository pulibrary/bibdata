class ChangeLengthOfChangeIdsUpdateIdsDeleteIds < ActiveRecord::Migration[4.2]
  def change
    change_column :dumps, :delete_ids, :text, limit: 16.megabytes
    change_column :dumps, :create_ids, :text, limit: 16.megabytes
    change_column :dumps, :update_ids, :text, limit: 16.megabytes
  end
end
