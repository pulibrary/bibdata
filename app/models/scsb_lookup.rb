class ScsbLookup
  include Scsb

  def find_by_id(id)
    response = items_by_id(id)
    response.map { |r| [r['itemBarcode'], r] }.to_h
  end

  def find_by_barcodes(barcodes)
    response = items_by_barcode(barcodes)
    response.map { |r| [r['itemBarcode'], r] }.to_h
  end

end
