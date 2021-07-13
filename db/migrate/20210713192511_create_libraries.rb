class CreateLibraries < ActiveRecord::Migration[5.2]
  def change
    create_table :libraries do |t|
      t.string :label
      t.string :code
      t.integer :order, default: 0

      t.timestamps null: false
    end
  end
end
