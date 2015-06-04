# This migration comes from locations (originally 20150520130710)
class CreateLocationsLibraries < ActiveRecord::Migration
  def change
    create_table :locations_libraries do |t|
      t.string :label
      t.string :code

      t.timestamps null: false
    end
  end
end
