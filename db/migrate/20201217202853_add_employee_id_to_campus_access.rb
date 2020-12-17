class AddEmployeeIdToCampusAccess < ActiveRecord::Migration[5.2]
  def change
    add_column :campus_accesses, :employee_id, :string
  end
end
