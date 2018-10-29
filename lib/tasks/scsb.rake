require './marc_to_solr/lib/index_functions'

namespace :scsb do
  desc 'starts monitoring jobs for loops'
  task :start_daemon do
    %x[bundle exec loops start -d 2>&1]
  end

  desc 'stops loops'
  task :stop_daemon do
    %x[bundle exec loops stop 2>&1]
  end

  desc "Index SCSB records with all changed records since SET_DATE, against SET_URL"
  task updates: :environment do
    if ENV['SET_URL'] && ENV['SET_DATE']
      solr_url = ENV['SET_URL']
      comp_time = Time.parse(ENV['SET_DATE'])
      solr = IndexFunctions.rsolr_connection(solr_url)
      dump_type = DumpType.find_by(constant: 'PARTNER_RECAP')
      dump_file_type = DumpFileType.find_by(constant: 'RECAP_RECORDS')
      dumps = Dump.where(dump_type: dump_type, created_at: comp_time..Time.now)
      dumps.each do |dump|
        dump.dump_files.each do |df|
          next unless df.dump_file_type == dump_file_type
          df.unzip
          sh "traject -c marc_to_solr/lib/traject_config.rb #{df.path} -u #{solr_url}; true"
          df.zip
        end
        solr.delete_by_id(dump.delete_ids) if dump.delete_ids
      end
      solr.commit
    end
  end

  desc "Index SCSB records with most recent update, against SET_URL"
  task latest: :environment do
    if ENV['SET_URL']
      solr_url = ENV['SET_URL']
      solr = IndexFunctions.rsolr_connection(solr_url)
      dump_type = DumpType.find_by(constant: 'PARTNER_RECAP')
      dump_file_type = DumpFileType.find_by(constant: 'RECAP_RECORDS')
      dumps = Dump.where(dump_type: dump_type)
      dump = dumps.last
      dump.dump_files.each do |df|
        next unless df.dump_file_type == dump_file_type
        df.unzip
        sh "traject -c marc_to_solr/lib/traject_config.rb #{df.path} -u #{solr_url}; true"
        df.zip
      end
      solr.delete_by_id(dump.delete_ids) if dump.delete_ids
      solr.commit
    end
  end

end
