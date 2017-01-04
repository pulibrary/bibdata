namespace :workers do

  desc 'Unregisters and stops worker processes'
  task :stop do
    Resque::Worker.all.each {|w| w.shutdown}
    Resque::Worker.all.each {|w| w.unregister_worker}
    %x[kill -QUIT `ps aux | grep [r]esque | grep -v grep | cut -c 10-16`]
  end

  desc 'Sets up 5 workers in background'
  task :start do
  	%x[PIDFILE=./resque.pid COUNT=5 BACKGROUND=yes QUEUE=* bundle exec rake resque:workers >> log/resque.log 2>&1]
    %x[resque-web -L]
  end

end
