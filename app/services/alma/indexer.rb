require 'rubygems/package'
class Alma::Indexer
  include Rails.application.routes.url_helpers
  attr_reader :solr_url
  def initialize(solr_url:)
    @solr_url = solr_url
  end

  def full_reindex!
    full_reindex_file_paths.each do |path|
      decompress_file(path) do |file|
        index_file(file.path)
      end
    end
  end

  def incremental_index!(dump)
    dump.dump_files.each do |dump_file|
      decompress_file(dump_file.path) do |file|
        index_file(file.path)
      end
    end
  end

  def index_file(file_name, debug_mode = false)
    debug_flag = debug_mode ? "--debug-mode" : ""
    `traject #{debug_flag} -c marc_to_solr/lib/traject_config.rb #{file_name} -u #{solr_url}; true`
  end

  def default_url_options
    Rails.configuration.action_mailer.default_url_options
  end

  private

    def decompress_file(file_path)
      tar_reader(file_path).each.map do |entry|
        Tempfile.create(decompressed_filename(entry), binmode: true) do |decompressed_tmp|
          decompressed_file = write_chunks(entry, decompressed_tmp)
          entry.close
          yield(decompressed_file)
        end
      end
    end

    def tar_reader(path)
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
      tar_extract.tap(&:rewind)
    end

    def write_chunks(entry, temp_file)
      while (chunk = entry.read(16 * 1024))
        temp_file.write chunk
      end
      temp_file.tap(&:rewind)
    end

    def decompressed_filename(entry)
      file_name, decompress_extension = entry.full_name.split(".")
      decompress_extension ||= "xml"
      ["full_reindex_file_unzip_#{file_name}", "." + decompress_extension]
    end

    def full_reindex_event
      Event.joins(dump: :dump_type).where(success: true, 'dump_types.constant': "ALL_RECORDS").order(finish: 'DESC').first!
    end

    def full_reindex_files
      full_reindex_event.dump.dump_files.joins(:dump_file_type).where('dump_file_types.constant': 'BIB_RECORDS')
    end

    def full_reindex_file_paths
      full_reindex_files.map(&:path)
    end
end
