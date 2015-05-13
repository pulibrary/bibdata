require 'json'
require 'faraday'
require 'zlib'
require 'rsolr'
require 'time'

module IndexFunctions

  def self.update_records(event, solr_url)
    dump = JSON.parse(Faraday.get(event['dump_url']).body)
    
    # updates
    dump['files']['updated_records'].each_with_index do |update, i|     
      File.write('/tmp/update.gz', Faraday.get(dump['files']['updated_records'][i]['dump_file']).body)      
      Zlib::GzipReader.open('/tmp/update.gz') do |gz|
        File.open("/tmp/update.xml", "w") do |g|
          IO.copy_stream(gz, g)
        end
      end 
      #sh "traject -c lib/traject_config.rb /tmp/update.xml -u #{solr_url}"
    end

    # new records
    dump['files']['new_records'].each_with_index do |new, i|     
      File.write('/tmp/new.gz', Faraday.get(dump['files']['new_records'][0]['dump_file']).body)      
      Zlib::GzipReader.open('/tmp/new.gz') do |gz|
        File.open("/tmp/new.xml", "w") do |g|
          IO.copy_stream(gz, g)
        end
      end 
      #sh "traject -c lib/traject_config.rb /tmp/new.xml -u #{solr_url}"
    end  

    # delete records
    delete_ids = {"delete" => dump['ids']['delete_ids'].each {|i| i.keep_if{|k,v| k == 'id'} } }
    File.open("/tmp/delete_ids.json", "w") {|f| f.write(delete_ids.to_json)}
    #sh "curl '#{solr_url}/update/json?commit=true' --data-binary @/tmp/delete_ids.json -H 'Content-type:application/json'"
  end

  def self.changed_since(events)
  end

  def self.changed_on(events)
  end

end