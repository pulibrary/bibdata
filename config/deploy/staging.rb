# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

set :application, 'bibdata'
set :stage, :production
set :rails_env, 'staging'
# begin old boxes
server 'bibdata-alma-staging1.princeton.edu', user: 'deploy', roles: [:web, :app, :db, :hr_cron]
server 'bibdata-alma-staging2.princeton.edu', user: 'deploy', roles: [:web, :app, :db, :hr_cron]
# Worker 1 gets the poller daemon installed via Princeton Ansible
server 'bibdata-alma-worker-staging1.princeton.edu', user: 'deploy', roles: [:db, :worker, :cron, :cron_staging, :poller]
server 'bibdata-alma-worker-staging2.princeton.edu', user: 'deploy', roles: [:db, :worker, :cron, :cron_staging]
# end old boxes

# begin new boxes
server 'bibdata-staging1.princeton.edu', user: 'deploy', roles: [:web, :app, :db]
server 'bibdata-staging2.princeton.edu', user: 'deploy', roles: [:web, :app]
# Worker 1 gets the poller daemon installed via Princeton Ansible
server 'bibdata-worker-staging1.princeton.edu', user: 'deploy', roles: [:worker, :cron, :cron_staging, :poller]
server 'bibdata-worker-staging2.princeton.edu', user: 'deploy', roles: [:worker]
# end new boxes

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

# server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
