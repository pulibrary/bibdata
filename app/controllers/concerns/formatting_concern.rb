module FormattingConcern
  extend ActiveSupport::Concern
  # @param records [MARC::Record] Could be one or a collection
  # @return [String] A serialized <mrx:record/> or <mrx:collection/>
  # "Cleans" the record of invalid xml characters
  def records_to_xml_string(records)
    if records.kind_of? Array
      xml_str = ''
      StringIO.open(xml_str) do |io|
        writer = MARC::XMLWriter.new(io)
        records.each do |r|
          writer.write(r) unless r.nil?
        end
        writer.close()
      end
      VoyagerHelpers::Liberator.valid_xml(xml_str)
    else
      VoyagerHelpers::Liberator.valid_xml(records.to_xml.to_s)
    end
  end

  # Quick cheat to help clean up character encoding problems by passing the
  # records through an XML parser
  #
  # @param records [MARC::Record] Could be one or a collection
  # @return [Hash] If only one record was passed
  # @return [Array<Hash>]
  def pass_records_through_xml_parser(records)
    reader = MARC::XMLReader.new(StringIO.new( records_to_xml_string(records) ))
    record_hashes = []
    reader.each { |r| record_hashes << r.to_hash }
    if record_hashes.length == 1
      record_hashes.first
    else
      record_hashes
    end
  end

  def valid_barcode(barcode)
    valid_barcode = false
    if barcode =~ /^32101[0-9]{9}$/
      valid_barcode = true
    end
  end

  def statuses_to_xml(data)
    # yep!
    s = []
    s << '<statuses>'
    data.each { |k,v| s << %Q(<status code="#{k}" label="#{v}" />) }
    s << '</statuses>'
    s.join('')
  end
end
