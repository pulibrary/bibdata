namespace :scsb do
  desc 'Index SCSB records with all changed records since SET_DATE, against SET_URL'
  task updates: :environment do
    if ENV.fetch('SET_URL', nil) && ENV.fetch('SET_DATE', nil)
      comp_time = Time.parse(ENV.fetch('SET_DATE', nil))
      dumps = Dump.partner_recap.where(generated_date: comp_time..Time.now)
      IndexFunctions.process_scsb_dumps(dumps, ENV.fetch('SET_URL', nil))
    end
  end

  desc 'Index SCSB incremental record set with most recent update, against SET_URL'
  task latest: :environment do
    if ENV['SET_URL']
      dumps = Dump.partner_recap
      IndexFunctions.process_scsb_dumps([dumps.last], ENV.fetch('SET_URL', nil))
    end
  end

  desc 'Index most recent SCSB full record set and any subsequent incrementals against SET_URL'
  task full: :environment do
    abort 'usage: SET_URL=[solr_url]' unless ENV['SET_URL']
    dump = Dump.partner_recap_full.latest_generated
    subsequent = dump.subsequent_partner_incrementals
    IndexFunctions.process_scsb_dumps([dump] + subsequent, ENV.fetch('SET_URL', nil))
  end

  desc 'Adds a local dump file to the database'
  task add_local_dump_file: :environment do
    abort 'usage: FILE=full-file-path.xml.gz rake scsb:add_local_dump_file' unless ENV['FILE']
    ev = Event.new(success: true)
    ev.save

    dump_type = ENV.fetch('DUMP_TYPE', nil) || :partner_recap
    dump = Dump.new(event_id: ev.id, dump_type: dump_type.downcase.to_sym)
    dump.save

    dump_file_type = ENV.fetch('DUMP_FILE_TYPE', nil) || :recap_records
    dump_file = DumpFile.new(dump_id: dump.id, dump_file_type: dump_file_type.downcase.to_sym,
                             path: ENV.fetch('FILE', nil))
    dump_file.save
  end

  desc 'Request full partner records from SCSB API'
  task :request_records, %i[scsb_env email institution_code] => :environment do |_t, args|
    unless ENV['SCSB_AUTH_KEY']
      abort 'usage: bundle exec rake scsb:request_records[scsb_env,email,institution_code] SCSB_AUTH_KEY=auth-key'
    end
    scsb_env = args.scsb_env.downcase
    abort 'scsb_env must be set to either uat or production' unless %w[uat production].include?(scsb_env)

    institution_code = args.institution_code.upcase
    abort 'institution_code must be set to CUL, NYPL, or HL' unless %w[CUL NYPL HL].include?(institution_code)

    scsb_records_request = ScsbFullRecordsRequest.new(scsb_env, args.email)
    # Request records from each institution - each call must be made separately
    puts("Requesting records for #{institution_code}")
    response = scsb_records_request.scsb_request(institution_code)
    puts("#{institution_code} response: #{response.body}")

    puts('Request complete, you should receive emails from recaplib.org when the job is started and completed')
  end

  namespace :import do
    desc 'Creates an Event and downloads files for a full partner record set'
    task full: :environment do
      ScsbImportFullJob.perform_async
    end

    desc 'Used for monthly cron job - downloads files for full partner record set only on Saturdays'
    task full_saturdays_only: :environment do
      unless Date.today.saturday?
        abort 'This task will only run on Saturdays, to facilitate monthly cron job. If you want to run this job manually on another day, use scsb:import:full'
      end
      ScsbImportFullJob.perform_async
    end
  end
end
