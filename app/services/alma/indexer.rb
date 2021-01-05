require 'rubygems/package'
class Alma::Indexer
  include Rails.application.routes.url_helpers
  attr_reader :solr_url
  def initialize(solr_url:)
    @solr_url = solr_url
  end

  def full_reindex!
    downloaded_full_reindex_files.each do |file|
      `traject -c marc_to_solr/lib/traject_config.rb #{file.path} -u #{solr_url}; true`
    end
  end

  def default_url_options
    Rails.configuration.action_mailer.default_url_options
  end

  private

    def downloaded_full_reindex_files
      @downloaded_full_reindex_files ||=
        begin
          full_reindex_file_urls.flat_map do |url|
            extension = "." + url.split("/").last.split(".", 2).last
            temp_file = Tempfile.new(["full_reindex_file", extension])
            temp_file.puts Faraday.get(url).body
            temp_file.rewind
            unzip(temp_file, extension)
          end
        end
    end

    def unzip(file, _ext)
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(file.path))
      tar_extract.rewind
      tar_extract.each.map do |entry|
        file_name, extension = entry.full_name.split(".")
        extension ||= "xml"
        unzipped_file = Tempfile.new(["full_reindex_file_unzip_#{file_name}", "." + extension])
        while (chunk = entry.read(16 * 1024))
          unzipped_file.write chunk
        end
        entry.close
        unzipped_file.tap(&:rewind)
      end
    end

    def full_reindex_event
      Event.joins(dump: :dump_type).where(success: true, 'dump_types.constant': "ALL_RECORDS").order(finish: 'DESC').first!
    end

    def full_reindex_files
      full_reindex_event.dump.dump_files.joins(:dump_file_type).where('dump_file_types.constant': 'BIB_RECORDS')
    end

    def full_reindex_file_urls
      @full_reindex_file_urls ||=
        begin
          full_reindex_files.map do |file|
            dump_file_url(file.id)
          end
        end
    end
end
