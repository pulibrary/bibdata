class ScsbLookup
  include Scsb

  def find_by_id(id)
    response = items_by_id(id)
  end

  def find_by_barcodes(barcodes)
    response = items_by_barcode(barcodes)
  end
end
