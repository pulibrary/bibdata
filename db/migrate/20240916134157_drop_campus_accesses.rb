class DropCampusAccesses < ActiveRecord::Migration[7.1]
  def change
    drop_table :campus_accesses
  end
end
