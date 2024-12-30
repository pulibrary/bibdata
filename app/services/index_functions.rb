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
    RSolr.connect(url: solr_url, timeout: 300, open_timeout: 300)
  rescue StandardError => e
    logger.error "Failed to connect to Solr: #{e.message}"
    nil
  end

  def self.process_scsb_dumps(dumps, solr_url)
    solr = rsolr_connection(solr_url)
    return if solr.nil?

    dumps.each do |dump|
      dump.dump_files.each do |df|
        next unless df.recap_record_type?

        DumpFileIndexJob.perform_async(df.id, solr_url)
      end
      solr.delete_by_id(dump.delete_ids) if dump.delete_ids.present?
    end
  end
end
