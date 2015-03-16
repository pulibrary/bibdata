class RemoveDumpCountColumns < ActiveRecord::Migration
  def change
    remove_column :dumps, :number_created
    remove_column :dumps, :number_updated
    remove_column :dumps, :number_deleted
  end
end
