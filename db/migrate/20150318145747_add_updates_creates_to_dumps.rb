class AddUpdatesCreatesToDumps < ActiveRecord::Migration
  def change
    change_table :dumps do |t|
      t.text :update_ids
      t.text :create_ids
    end
  end
end
