# This migration comes from locations (originally 20160610203622)
class CreateLocationsFloors < ActiveRecord::Migration[4.2]
  def change
    create_table :locations_floors do |t|
      t.string :label
      t.string :floor_plan_image
      t.string :starting_point
      t.string :walkable_areas

      t.timestamps null: false
    end
  end
end
