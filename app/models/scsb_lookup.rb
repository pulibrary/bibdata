class ScsbLookup
  include Scsb

  def find_by_id(id)
    response = items_by_id(id)
    response.index_by { |r| r['itemBarcode'] }
  rescue Faraday::ConnectionFailed
    Rails.logger.warn("No barcodes could be retrieved for the item: #{id}")
    {}
  end

  def find_by_barcodes(barcodes)
    response = items_by_barcode(barcodes)
    response.index_by { |r| r['itemBarcode'] }
  rescue Faraday::ConnectionFailed
    Rails.logger.warn("No items could be retrieved for the barcodes: #{barcodes.join(',')}")
    {}
  end
end
