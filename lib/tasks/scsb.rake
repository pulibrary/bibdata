namespace :scsb do
  desc 'starts monitoring jobs for loops'
  task :start_daemon do
    %x[bundle exec loops start -d 2>&1]
  end

  desc 'stops loops'
  task :stop_daemon do
    %x[bundle exec loops stop 2>&1]
  end

end
