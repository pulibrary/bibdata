# Service to decompress MARCXML stored in Solr
# The MARCXML field is stored as gzip-compressed, base64-encoded strings
class MarcxmlCompressor
  # Decompress a MARCXML string from Solr
  # @param compressed_string [String] Base64-encoded gzipped MARCXML
  # @return [String] Decompressed MARCXML string
  def self.decompress(compressed_string)
    return nil if compressed_string.blank?

    decoded = Base64.strict_decode64(compressed_string)
    Zlib::GzipReader.new(StringIO.new(decoded)).read
  end

  # @param xml_string [String] MARCXML string
  # @return [String] Base64-encoded gzipped MARCXML
  def self.compress(xml_string)
    return nil if xml_string.blank?

    compressed = StringIO.new
    Zlib::GzipWriter.wrap(compressed) { |gz| gz.write(xml_string) }
    Base64.strict_encode64(compressed.string)
  end
end
