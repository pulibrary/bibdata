class CreateDumpFiles < ActiveRecord::Migration
  def change
    create_table :dump_files do |t|
      t.references :dump, index: true
      t.string :path
      t.string :md5

      t.timestamps null: false
    end
    add_foreign_key :dump_files, :dumps
  end
end
