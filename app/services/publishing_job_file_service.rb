require 'rubygems/package'
class PublishingJobFileService
  attr_reader :path
  def initialize(path:)
    @path = path
  end

  def cache
    marc_records.each do |marc_record|
      id = marc_record["001"].value
      CachedMarcRecord.find_or_create_by(bib_id: id).tap do |record|
        record.marc = marc_record.to_xml
        record.save
      end
    end
  end

  def marc_records
    tar_extract.tap(&:rewind)
    tar_extract.map do |tar_entry|
      content = StringIO.new(tar_entry.read)
      MARC::XMLReader.new(content, external_encoding: "UTF-8").to_a.compact
    end.flatten
  end

  private

    def tar_extract
      @tar_extract ||= Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
    end
end
