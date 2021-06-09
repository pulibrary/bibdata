class AddIndexStatusToDumps < ActiveRecord::Migration[5.2]
  def change
    add_column :dumps, :index_status, :string
  end
end
