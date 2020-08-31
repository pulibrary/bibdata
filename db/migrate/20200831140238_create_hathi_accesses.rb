class CreateHathiAccesses < ActiveRecord::Migration[5.2]
  def change
    create_table :hathi_accesses do |t|
      t.string :oclc_number
      t.string :bibid
      t.string :status
      t.string :origin

      t.timestamps
    end
  end
end
