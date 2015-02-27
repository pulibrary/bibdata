class CreateDumpTypes < ActiveRecord::Migration
  def change
    create_table :dump_types do |t|
      t.string :label
      t.string :constant, index: true

      t.timestamps null: false
    end
  end
end
