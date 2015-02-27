class CreateDumps < ActiveRecord::Migration
  def change
    create_table :dumps do |t|
      t.references :event, index: true
      t.references :dump_type, index: true
      t.text :delete_ids
      t.integer :number_created
      t.integer :number_updated
      t.integer :number_deleted
      t.timestamps null: false
    end
    add_foreign_key :dumps, :events
    add_foreign_key :dumps, :dump_types
  end
end


