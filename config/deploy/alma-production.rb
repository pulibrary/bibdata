set :stage, :production
set :rails_env, 'production'
server 'bibdata-alma1.princeton.edu', user: 'deploy', roles: [:web, :app, :db]
server 'bibdata-alma2.princeton.edu', user: 'deploy', roles: [:web, :app, :db, :hr_cron]
server 'bibdata-alma-worker1.princeton.edu', user: 'deploy', roles: [:db, :worker, :cron, :cron_production]
server 'bibdata-alma-worker2.princeton.edu', user: 'deploy', roles: [:db, :worker]
server 'bibdata-alma-worker3.princeton.edu', user: 'deploy', roles: [:db, :worker]
