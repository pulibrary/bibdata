class AddNewDumpTypeToDump < ActiveRecord::Migration[7.0]
  def up
    add_column :dumps, :new_dump_type, :integer

    Dump.update_all("new_dump_type=dump_type_id")

    remove_reference :dumps, :dump_type
    rename_column :dumps, :new_dump_type, :dump_type
  end

  def down
    rename_column :dumps, :dump_type, :new_dump_type

    add_reference :dumps, :dump_type, type: :integer, index: true
    Dump.update_all("dump_type_id=new_dump_type")

    remove_column :dumps, :new_dump_type, :integer
  end
end
