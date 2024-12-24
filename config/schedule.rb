# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :job_template, "bash -l -c 'export PATH=\"/usr/local/bin/:$PATH\" && :job'"

# USING CAPISTRANO ROLES
# a job with no roles will deploy to all servers
# otherwise use roles to say which server it should go to
# e.g. every 1.day, at: '2:00am', roles: [:cron_staging] do

# OUTPUT
# add an `output` key to your args hash to write to a file (examples below)

# ENVIRONMENT VARIABLES
# I've created custom job types when we need to use env vars that aren't
#   written into whenever (like mailto)

# populate the figgy ark cache
every 1.day, at: '3:00am' do
  rake 'liberate:arks:clear_and_seed_cache'
end

job_type :liberate_latest_production,
         'cd :path && :environment_variable=:environment SET_URL=:set_url :bundle_command rake :task --silent :output'

# Daily recap shared collection update to Solr
every 1.day, at: '6:30am', roles: [:cron_production] do
  liberate_latest_production(
    'scsb:latest',
    set_url: ENV.fetch('SOLR_URL', nil),
    output: '/tmp/daily_updates.log'
  )
end

every 1.day, at: '6:00am', roles: [:cron_production] do
  rake 'marc_liberation:partner_update', output: '/tmp/cron_log.log'
end

# delete old events, dumps, and files on disk
every 1.week, roles: %i[cron_staging cron_production] do
  rake 'marc_liberation:delete:events'
end

every 2.weeks, at: '7:00am', roles: [:cron_production] do
  rake 'scsb:request_records[production,mk8066@princeton.edu,CUL]', output: '/tmp/cron_log.log'
end

every 2.weeks, at: '3:00pm', roles: [:cron_production] do
  rake 'scsb:request_records[production,mk8066@princeton.edu,NYPL]', output: '/tmp/cron_log.log'
end

every 2.weeks, at: '11:00pm', roles: [:cron_production] do
  rake 'scsb:request_records[production,mk8066@princeton.edu,HL]', output: '/tmp/cron_log.log'
end

# Runs on the second Saturday of the month at 9:00 am
every '0 9 8-14 * *', roles: [:cron_production] do
  rake 'scsb:import:full_saturdays_only', output: '/tmp/cron_log.log'
end
