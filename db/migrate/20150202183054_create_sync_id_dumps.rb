class CreateSyncIdDumps < ActiveRecord::Migration
  def change
    create_table :sync_id_dumps do |t|
      t.references :sync_event, index: true
      t.timestamps null: false
    end
    add_foreign_key :sync_id_dumps, :sync_events
  end
end
