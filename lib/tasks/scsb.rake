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
      comp_time = Time.parse(ENV['SET_DATE'])
      dumps = Dump.partner_recap.where(generated_date: comp_time..Time.now)
      IndexFunctions.process_scsb_dumps(dumps, ENV['SET_URL'])
    end
  end

  desc "Index SCSB incremental record set with most recent update, against SET_URL"
  task latest: :environment do
    if ENV['SET_URL']
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
    abort "usage: FILE=full-file-path.xml.gz rake scsb:add_local_dump_file" unless ENV['FILE']
    ev = Event.new(success: true)
    ev.save

    dump_type = ENV['DUMP_TYPE'] || :partner_recap
    dump = Dump.new(event_id: ev.id, dump_type: dump_type.downcase.to_sym)
    dump.save

    dump_file_type = ENV['DUMP_FILE_TYPE'] || :recap_records
    dump_file = DumpFile.new(dump_id: dump.id, dump_file_type: dump_file_type.downcase.to_sym, path: ENV['FILE'])
    dump_file.save
  end

  desc "Request full partner records from SCSB API"
  task :request_records, [:scsb_env, :email, :institution_code] => :environment do |_t, args|
    abort "usage: bundle exec rake scsb:request_records[scsb_env,email,institution_code] SCSB_AUTH_KEY=auth-key" unless ENV['SCSB_AUTH_KEY']
    scsb_env = args.scsb_env.downcase
    abort "scsb_env must be set to either uat or production" unless scsb_env == "uat" || scsb_env == "production"

    institution_code = args.institution_code.upcase
    abort "institution_code must be set to CUL, NYPL, or HL" unless institution_code == 'CUL' || institution_code == 'NYPL' || institution_code == 'HL'

    scsb_records_request = ScsbFullRecordsRequest.new(scsb_env, args.email)
    # Request records from each institution - each call must be made separately
    puts("Requesting records for #{institution_code}")
    response = scsb_records_request.scsb_request(institution_code)
    puts("#{institution_code} response: #{response.body}")

    puts("Request complete, you should receive emails from recaplib.org when the job is started and completed")
  end

  namespace :import do
    desc "Creates an Event and downloads files for a full partner record set"
    task full: :environment do
      ScsbImportFullJob.perform_later
    end

    desc "Used for monthly cron job - downloads files for full partner record set only on Saturdays"
    task full_saturdays_only: :environment do
      abort "This task will only run on Saturdays, to facilitate monthly cron job. If you want to run this job manually on another day, use scsb:import:full" unless Date.today.saturday?
      ScsbImportFullJob.perform_later
    end
  end
end
