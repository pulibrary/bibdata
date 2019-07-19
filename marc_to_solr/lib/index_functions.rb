require 'json'
require 'faraday'
require 'zlib'
require 'rsolr'
require 'time'
require 'logger'

module IndexFunctions

  def self.update_records(dump)
    file_paths = []
    dump['files']['updated_records'].each_with_index do |update, i|
      File.binwrite("/tmp/update_#{i}.gz", Faraday.get(update['dump_file']).body)
      file_paths << "/tmp/update_#{i}"
    end
    file_paths
  end

  def self.delete_ids(dump)
    dump['ids']['delete_ids']
  end

  def self.logger
    return Rails.logger if defined?(Rails)

    @logger ||= Logger.new(STDOUT)
  end

  def self.rsolr_connection(solr_url)
    RSolr.connect(url: solr_url, read_timeout: 300, open_timeout: 300)
  rescue StandardError => error
    logger.error "Failed to connect to Solr: #{error.message}"
    nil
  end

  def self.full_dump(event)
    file_paths = []
    dump = JSON.parse(Faraday.get(event['dump_url']).body)
    dump['files']['bib_records'].each_with_index do |bib, i|
      File.binwrite("/tmp/bib_#{i}.gz", Faraday.get(bib['dump_file']).body)
      file_paths << "/tmp/bib_#{i}"
    end
    file_paths
  end

  def self.unzip_mrc(marc_dump)
    Zlib::GzipReader.open("#{marc_dump}.gz") do |gz|
      File.open("#{marc_dump}.mrc", 'wb') do |fp|
        while chunk = gz.read(16 * 1024) do
          fp.write chunk
        end
      end
      gz.close
    end
  end

  def self.unzip_xml(marc_dump)
    Zlib::GzipReader.open("#{marc_dump}.gz") do |gz|
      File.open("#{marc_dump}.xml", 'wb') do |fp|
        while chunk = gz.read(16 * 1024) do
          fp.write chunk
        end
      end
      gz.close
    end
  end

  def self.process_scsb_dumps(dumps, solr_url)
    solr = rsolr_connection(solr_url)
    return if solr.nil?

    dumps.each do |dump|
      dump.dump_files.each do |df|
        next unless df.recap_record_type?
        df.unzip
        system "traject -c marc_to_solr/lib/traject_config.rb #{df.path} -u #{solr_url}; true"
        df.zip
      end
      solr.delete_by_id(dump.delete_ids) if dump.delete_ids
    end
    solr.commit
  end
end
