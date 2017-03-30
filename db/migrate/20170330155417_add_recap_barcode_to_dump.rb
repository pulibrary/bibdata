class AddRecapBarcodeToDump < ActiveRecord::Migration
  def change
    add_column :dumps, :recap_barcodes, :text, limit: 16.megabytes
  end
end
