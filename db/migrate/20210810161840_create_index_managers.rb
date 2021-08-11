class CreateIndexManagers < ActiveRecord::Migration[5.2]
  def change
    create_table :index_managers do |t|
      t.string :solr_collection, index: { unique: true }
      t.references :dump_in_progress, foreign_key: { to_table: 'dumps' }
      t.references :last_dump_completed, foreign_key: { to_table: 'dumps' }

      t.timestamps
    end
  end
end
