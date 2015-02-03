class CreateSyncChanges < ActiveRecord::Migration
  def change
    create_table :sync_change_dumps do |t|
      t.references :sync_event, index: true
      t.text :delete_ids
      t.integer :number_created
      t.integer :number_updated
      t.integer :number_deleted

      t.timestamps null: false
    end
    add_foreign_key :sync_change_dumps, :sync_events
  end
end

