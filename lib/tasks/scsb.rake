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
      LocationMapsGeneratorService.generate if ENV['UPDATE_LOCATIONS']
      comp_time = Time.parse(ENV['SET_DATE'])
      dumps = Dump.partner_recap.where(created_at: comp_time..Time.now)
      IndexFunctions.process_scsb_dumps(dumps, ENV['SET_URL'])
    end
  end

  desc "Index SCSB incremental record set with most recent update, against SET_URL"
  task latest: :environment do
    if ENV['SET_URL']
      LocationMapsGeneratorService.generate if ENV['UPDATE_LOCATIONS']
      dumps = Dump.partner_recap
      IndexFunctions.process_scsb_dumps([dumps.last], ENV['SET_URL'])
    end
  end

  desc "Index most recent SCSB full record set and any subsequent incrementals against SET_URL"
  task full: :environment do
    abort "usage: SET_URL=[solr_url]" unless ENV['SET_URL']
    dump = Dump.partner_recap_full.latest_generated
    subsequent = dump.subsequent_partner_incrementals
    IndexFunctions.process_scsb_dumps([dump] + subsequent, ENV['SET_URL'])
  end

  desc "Adds a local dump file to the database"
  task add_local_dump_file: :environment do
    abort "usage: FILE=full-file-path.xml.gz rake add_local_dump_file" unless ENV['FILE']
    ev = Event.new(success: true)
    ev.save

    dump_type = ENV['DUMP_TYPE'] || "PARTNER_RECAP"
    dump_type_id = DumpType.where(constant: dump_type).first.id
    dump = Dump.new(event_id: ev.id, dump_type_id: dump_type_id)
    dump.save

    dump_file_type = ENV['DUMP_FILE_TYPE'] || "RECAP_RECORDS"
    dump_file_type_id = DumpFileType.where(constant: dump_file_type).first.id
    dump_file = DumpFile.new(dump_id: dump.id, dump_file_type_id: dump_file_type_id, path: ENV['FILE'])
    dump_file.save
  end

  namespace :import do
    desc "Creates an Event and downloads files for a full partner record set"
    task full: :environment do
      ScsbImportFullJob.perform_later
    end
  end
end
