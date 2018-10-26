require 'json'
require 'faraday'
require 'zlib'
require 'rsolr'
require 'time'

module IndexFunctions

  def self.update_records(dump)
    file_paths = []

    # updates
    dump['files']['updated_records'].each_with_index do |update, i|
      File.binwrite("/tmp/update_#{i}.gz", Faraday.get(update['dump_file']).body)
      file_paths << "/tmp/update_#{i}"
    end

    # new records
    dump['files']['new_records'].each_with_index do |new_records, i|
      File.binwrite("/tmp/new_#{i}.gz", Faraday.get(new_records['dump_file']).body)
      file_paths << "/tmp/new_#{i}"
    end

    file_paths
  end

  def self.delete_ids(dump)
    dump['ids']['delete_ids']
  end

  def self.rsolr_connection(solr_url)
    RSolr.connect(url: solr_url, read_timeout: 300, open_timeout: 300)
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
end
