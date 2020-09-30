class CampusAccessAddCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :campus_accesses, :category, :string, default: 'full'
  end
end
