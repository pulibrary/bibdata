module MarcSupport
  # @param path [String] Path on disk to the tar gzipped dump file
  # @return [Array<MARC::Record>] Array of MARC record objects
  def dump_file_to_marc(path:)
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
    tar_extract.tap(&:rewind)
    content = StringIO.new(tar_extract.first.read)
    MARC::XMLReader.new(content, external_encoding: 'UTF-8').to_a
  end
end

RSpec.configure do |config|
  config.include MarcSupport
end
