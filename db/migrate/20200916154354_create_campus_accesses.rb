class CreateCampusAccesses < ActiveRecord::Migration[5.2]
  def change
    create_table :campus_accesses do |t|
      t.string :uid

      t.timestamps
    end
    add_index :campus_accesses, :uid
  end
end
