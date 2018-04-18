# config valid only for current version of Capistrano
# lock '3.7.2'

set :application, 'marc_liberation'
set :repo_url, "https://github.com/pulibrary/marc_liberation.git"

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/opt/#{fetch(:application)}"
set :repo_path, "/opt/#{fetch(:application)}/repo"
# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

set :ssh_options, { forward_agent: true }

# Default value for :pty is false
# set :pty, true

# Default value for linked_dirs is []
set :linked_dirs, %w{
  tmp/pids
  tmp/cache
  tmp/sockets
  vendor/bundle
  public/system
  log
}


# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :figgy_ark_cache_path, 'tmp/figgy_ark_cache'
set :linked_dirs, fetch(:linked_dirs, []).push(fetch(:figgy_ark_cache_path))

namespace :sidekiq do
  task :quiet do
    # Horrible hack to get PID without having to use terrible PID files
    on roles(:worker) do
      puts capture("kill -USR1 $(sudo initctl status bibdata-workers | grep /running | awk '{print $NF}') || :")
    end
  end
  task :restart do
    on roles(:worker) do
      execute :sudo, :service, "bibdata-workers", :restart
    end
  end
end
after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:reverted', 'sidekiq:restart'
after 'deploy:published', 'sidekiq:restart'

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
