class CreateHoldingLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :holding_locations do |t|
      t.string :label
      t.string :code
      t.boolean :circulates, default: true
      t.integer :hours_location, foreign_key: true
      t.string :remote_storage
      t.boolean :aeon_location, default: false
      t.boolean :recap_electronic_delivery_location, default: false
      t.boolean :open, default: true
      t.boolean :requestable, default: true
      t.boolean :always_requestable, default: false
      t.boolean :circulates, default: true
      t.integer :holding_library_id

      t.timestamps null: false
    end
  end
end
