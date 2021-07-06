class AddIndexStatusToDumpFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :dump_files, :index_status, :integer, default: 0
  end
end
