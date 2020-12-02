module FormattingConcern
  extend ActiveSupport::Concern
  # @param records [MARC::Record] Could be one or a collection
  # @return [String] A serialized <mrx:record/> or <mrx:collection/>
  # "Cleans" the record of invalid xml characters
  def records_to_xml_string(records)
    # TODO: Re-enable. Disabled as we no longer have VoyagerHelpers.
    # if records.kind_of? Array
    #       xml_str = ''
    #       StringIO.open(xml_str) do |io|
    #         writer = MARC::XMLWriter.new(io)
    #         records.each do |r|
    #           writer.write(r) unless r.nil?
    #         end
    #         writer.close()
    #       end
    #       VoyagerHelpers::Liberator.valid_xml(xml_str)
    #     elsif records.kind_of? String
    #       # example response from /almaws/v1/bibs/{mms_id}/holdings
    #       valid_xml(records)
    #     else
    # valid_xml(records.to_xml.to_s)
    records.to_xml.to_s
    # end
  end

  # Moved from voyager-helpers
  # strips invalid xml characters to prevent parsing errors
  # only used for "cleaning" individually retrieved records
  def valid_xml(xml_string)
    invalid_xml_range = /[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD]/
    xml_string.gsub(invalid_xml_range, '')
  end

  # Clean up character encoding problems by passing the
  # records through an XML parser
  # @param records [MARC::Record] Could be one or a collection
  # @return [Hash] If only one record was passed
  # @return [Array<Hash>]
  def pass_records_through_xml_parser(records)
    reader = MARC::XMLReader.new(StringIO.new(records_to_xml_string(records)))
    record_hashes = []
    reader.each { |r| record_hashes << r.to_hash }
    if record_hashes.length == 1
      record_hashes.first
    else
      record_hashes
    end
  end

  def valid_barcode?(barcode)
    (barcode =~ /^(32101[0-9]{9}|PULTST[0-9]{5})$/) == 0
  end

  def statuses_to_xml(data)
    # yep!
    s = []
    s << '<statuses>'
    data.each { |k, v| s << %(<status code="#{k}" label="#{v}" />) }
    s << '</statuses>'
    s.join('')
  end
end
