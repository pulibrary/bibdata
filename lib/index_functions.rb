require 'json'
require 'faraday'
require 'zlib'
require 'rsolr'
require 'time'

module IndexFunctions

  def self.update_records(event, solr_url)
    file_paths = []
    dump = JSON.parse(Faraday.get(event['dump_url']).body)
    
    # updates
    dump['files']['updated_records'].each_with_index do |update, i|
      File.write("/tmp/update_#{i}.gz", Faraday.get(update['dump_file']).body)
      Zlib::GzipReader.open("/tmp/update_#{i}.gz") do |gz|
        File.open("/tmp/update_#{i}.xml", 'w') do |fp|
          while chunk = gz.read(16 * 1024) do
            fp.write chunk
          end
        end
        gz.close
      end
      file_paths << "/tmp/update_#{i}"
    end

    # new records
    dump['files']['new_records'].each_with_index do |new_records, i|
      File.write("/tmp/new_#{i}.gz", Faraday.get(new_records['dump_file']).body)
      Zlib::GzipReader.open("/tmp/new_#{i}.gz") do |gz|
        File.open("/tmp/new_#{i}.xml", "w") do |fp|
          while chunk = gz.read(16 * 1024) do
            fp.write chunk
          end
        end
        gz.close
      end 
      file_paths << "/tmp/new_#{i}"
    end  

    # delete records
    delete_ids = {"delete" => dump['ids']['delete_ids'].each {|i| i.keep_if{|k,v| k == 'id'} } }
    File.open("/tmp/delete_ids.json", "w") {|f| f.write(delete_ids.to_json)}
    file_paths
  end

  def self.full_dump(event, solr_url)
    file_paths = []
    dump = JSON.parse(Faraday.get(event['dump_url']).body)

    dump['files']['bib_records'].each_with_index do |bib, i|
      File.write("/tmp/bib_#{i}.gz", Faraday.get(bib['dump_file']).body)
      Zlib::GzipReader.open("/tmp/bib_#{i}.gz") do |gz|
        File.open("/tmp/bib_#{i}.xml", 'w') do |fp|
          while chunk = gz.read(16 * 1024) do
            fp.write chunk
          end
        end
        gz.close
      end
      file_paths << "/tmp/bib_#{i}"
    end
    file_paths
  end

end