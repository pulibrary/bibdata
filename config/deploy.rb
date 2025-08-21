# config valid only for current version of Capistrano
# lock '3.7.2'

set :repo_url, "https://github.com/pulibrary/bibdata.git"

# Default branch is :main
set :branch, ENV['BRANCH'] || 'main'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, -> { "/opt/#{fetch(:application)}" }
set :repo_path, ->{ "/opt/#{fetch(:application)}/repo" }

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

set :ssh_options, { forward_agent: true }

set :passenger_restart_with_touch, true

# Default value for :pty is false
# set :pty, true

# Default value for linked_dirs is []
set :linked_dirs, %w{
  target
  tmp/pids
  tmp/cache
  tmp/figgy_ark_cache
  tmp/sockets
  vendor/bundle
  public/system
  log
}

set :linked_files, ['marc_to_solr/translation_maps/figgy_mms_ids.yaml']

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :keep_releases, 3

set :whenever_roles, ->{ [:cron, :cron_staging, :cron_production, :worker] }

namespace :sidekiq do
  task :restart do
    on roles(:worker) do
      execute :sudo, :service, "bibdata-workers", :restart
    end
  end
end

namespace :sqs_poller do
  task :restart do
    on roles(:poller) do
      execute :sudo, :service, "bibdata-sqs-poller", :restart
    end
  end
end

namespace :application do
  # You can/ should apply this command to a single host
  # cap --hosts=bibdata-staging1.lib.princeton.edu staging application:remove_from_nginx
  desc "Marks the server(s) to be removed from the loadbalancer"
  task :remove_from_nginx do
    count = 0
    on roles(:app) do
      count += 1
    end
    if count > (roles(:app).length / 2)
      raise "You must run this command on no more than half the servers utilizing the --hosts= switch"
    end
    on roles(:app) do
      within release_path do
        execute :touch, "public/remove-from-nginx"
      end
    end
  end

  # You can/ should apply this command to a single host
  # cap --hosts=bibdata-staging1.lib.princeton.edu staging application:serve_from_nginx
  desc "Marks the server(s) to be added back to the loadbalancer"
  task :serve_from_nginx do
    on roles(:app) do
      within release_path do
        execute :rm, "-f public/remove-from-nginx"
      end
    end
  end
end

after 'deploy:reverted', 'sidekiq:restart'
after 'deploy:published', 'sidekiq:restart'
after 'deploy:restart', 'sqs_poller:restart'

namespace :deploy do
  desc "Check that we can access everything"
  task :check_write_permissions do
    on roles(:all) do |host|
      if test("[ -w #{fetch(:deploy_to)} ]")
        info "#{fetch(:deploy_to)} is writable on #{host}"
      else
        error "#{fetch(:deploy_to)} is not writable on #{host}"
      end
    end
  end

  desc 'Compile Rust code'
  task :compile do
    on roles(:all) do
      within release_path do
        execute :rake, 'compile'
      end
    end
  end
  namespace :deploy do
    namespace :assets do
      before :compile_assets, :compile
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'
end
