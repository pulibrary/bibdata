class DropCachedMarcRecords < ActiveRecord::Migration[8.1]
  def up
    drop_table :cached_marc_records
  end

  def down
    create_table :cached_marc_records do |t|
      t.string :bib_id
      t.text :marc

      t.timestamps
    end
  end
end
