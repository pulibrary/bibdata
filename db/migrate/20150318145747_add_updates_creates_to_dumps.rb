class AddUpdatesCreatesToDumps < ActiveRecord::Migration[4.2]
  def change
    change_table :dumps do |t|
      t.text :update_ids
      t.text :create_ids
    end
  end
end
