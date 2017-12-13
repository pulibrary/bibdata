class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.datetime :start
      t.datetime :finish
      t.text :error
      t.boolean :success

      t.timestamps null: false
    end
  end
end
