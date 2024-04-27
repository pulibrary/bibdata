class AddNewDumpFileTypeToDumpFile < ActiveRecord::Migration[7.0]
  def up
    add_column :dump_files, :new_dump_file_type, :integer

    DumpFile.update_all("new_dump_file_type=dump_file_type_id")

    remove_reference :dump_files, :dump_file_type
    rename_column :dump_files, :new_dump_file_type, :dump_file_type
  end

  def down
    rename_column :dump_files, :dump_file_type, :new_dump_file_type

    add_reference :dump_files, :dump_file_type, type: :integer, index: true
    DumpFile.update_all("dump_file_type_id=new_dump_file_type")

    remove_column :dump_files, :new_dump_file_type, :integer
  end
end
