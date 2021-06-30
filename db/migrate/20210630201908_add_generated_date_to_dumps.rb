class AddGeneratedDateToDumps < ActiveRecord::Migration[5.2]
  def change
    add_column :dumps, :generated_date, :datetime
  end
end
