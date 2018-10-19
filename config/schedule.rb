# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

set :job_template, "bash -l -c 'export PATH=\"/usr/local/bin/:$PATH\" && :job'"

# a job with no roles will deploy to all servers
# otherwise use roles to say which server it should go to
# e.g. every 1.day, at: '2:00am', roles: [:cron_staging] do
every 1.day, at: '3:00am' do
  rake "liberate:arks:clear_and_seed_cache"
end
