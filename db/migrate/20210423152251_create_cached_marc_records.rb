class CreateCachedMarcRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :cached_marc_records do |t|
      t.string :bib_id
      t.text :marc

      t.timestamps
    end
  end
end
