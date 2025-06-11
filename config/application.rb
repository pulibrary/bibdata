require File.expand_path('boot', __dir__)

require 'rails/all'
require_relative 'lando_env' if Rails.env.development? || Rails.env.test?

# Require the gems listed in Gemfile, but only the default ones
# and those for the environment rails is running in
Bundler.require(:default, Rails.env)

module MarcLiberation
  class Application < Rails::Application
    config.active_support.cache_format_version = 7.0
    config.encoding = 'utf-8'
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.active_job.queue_adapter = :sidekiq

    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => 'GET',
      'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, Token'
    }

    config.ip_allowlist = []
    ip_allowlist = config_for(:ip_allowlist)
    ip_allowlist_addresses = ip_allowlist['addresses']
    config.ip_allowlist = ip_allowlist_addresses.split if ip_allowlist_addresses

    config.traject = config_for(:traject)
    config.solr = config_for(:solr)

    config.authz = []
    authz = config_for(:authz)
    netids = authz['netids']
    config.authz = netids.split if netids

    config.alma = config_for(:alma).with_indifferent_access
  end
end
