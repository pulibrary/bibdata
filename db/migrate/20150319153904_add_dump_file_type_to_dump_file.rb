class AddDumpFileTypeToDumpFile < ActiveRecord::Migration[4.2]
  def change
    change_table :dump_files do |t|
      t.belongs_to :dump_file_type, index: true
    end
  end
end
