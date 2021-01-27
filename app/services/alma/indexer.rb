require 'rubygems/package'
class Alma::Indexer
  include Rails.application.routes.url_helpers
  attr_reader :solr_url
  def initialize(solr_url:)
    @solr_url = solr_url
  end

  def full_reindex!
    full_reindex_file_urls.each do |url|
      download_and_decompress(url) do |file|
        `traject -c marc_to_solr/lib/traject_config.rb #{file.path} -u #{solr_url}; true`
      end
    end
  end

  def default_url_options
    Rails.configuration.action_mailer.default_url_options
  end

  private

    def download_and_decompress(url)
      extension = "." + url.split("/").last.split(".", 2).last
      Tempfile.create(["full_reindex_file", extension], tmpdir, binmode: true) do |temp_file|
        temp_file.puts Faraday.get(url).body
        temp_file.rewind


        tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(temp_file.path))
        tar_extract.rewind
        tar_extract.each.map do |entry|
          file_name, extension = entry.full_name.split(".")
          extension ||= "xml"
          Tempfile.create(["full_reindex_file_unzip_#{file_name}", "." + extension], tmpdir, binmode: true) do |unzipped_file|
            while (chunk = entry.read(16 * 1024))
              unzipped_file.write chunk
            end
            entry.close
            unzipped_file.tap(&:rewind)
            yield(unzipped_file)
          end
        end
      end
    end

    def tmpdir
      MARC_LIBERATION_CONFIG["tmpdir"]
    end

    def full_reindex_event
      Event.joins(dump: :dump_type).where(success: true, 'dump_types.constant': "ALL_RECORDS").order(finish: 'DESC').first!
    end

    def full_reindex_files
      full_reindex_event.dump.dump_files.joins(:dump_file_type).where('dump_file_types.constant': 'BIB_RECORDS')
    end

    def full_reindex_file_urls
      full_reindex_files.map { |file| dump_file_url(file.id) }
    end
end
