class AddInProgressToIndexManager < ActiveRecord::Migration[5.2]
  def change
    add_column :index_managers, :in_progress, :boolean
  end
end
