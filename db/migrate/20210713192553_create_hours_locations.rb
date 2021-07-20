class CreateHoursLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :hours_locations do |t|
      t.string :code
      t.string :label

      t.timestamps null: false
    end
  end
end
