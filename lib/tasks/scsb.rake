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
      dumps = Dump.where(dump_type: DumpType.find_by(constant: 'PARTNER_RECAP'),
                         created_at: comp_time..Time.now)
      IndexFunctions.process_scsb_dumps(dumps, ENV['SET_URL'])
    end
  end

  desc "Index SCSB records with most recent update, against SET_URL"
  task latest: :environment do
    if ENV['SET_URL']
      dumps = Dump.where(dump_type: DumpType.find_by(constant: 'PARTNER_RECAP'))
      IndexFunctions.process_scsb_dumps([dumps.last], ENV['SET_URL'])
    end
  end
end
