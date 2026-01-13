source 'https://rubygems.org'
source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro'
end

# pin the alma gem until we adress https://github.com/pulibrary/bibdata/pull/2502
gem 'alma', '~> 0.5.0'
gem 'aws-sdk-s3'
gem 'aws-sdk-sqs'
gem 'bcrypt_pbkdf'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'capybara'
gem 'change_the_subject', github: 'pulibrary/change_the_subject', branch: 'main'
gem 'devise'
gem 'ed25519'
gem 'faraday', '~> 1.0'
gem 'faraday_middleware', '~> 1.0'
gem 'ffi', '>= 1.9.25'
gem 'flipflop'
gem 'friendly_id'
gem 'health-monitor-rails', '12.9.0'
gem 'high_voltage', '~> 3.0'
gem 'honeybadger'
gem 'human_languages', '~> 0.7'
gem 'jbuilder'
gem 'jquery-rails'
gem 'jquery-tablesorter', '~> 1.21'
gem 'lcsort'
gem 'library_standard_numbers'
gem 'lightly', '~> 0.2.1'
gem 'lograge'
gem 'logstash-event'
gem 'loofah', '>= 2.22'
gem 'marc', '~> 1.0'
gem 'marc_cleanup', github: 'pulibrary/marc_cleanup', require: false
gem 'multi_json'
gem 'mutex_m'
gem 'net-imap', require: false
gem 'net-ldap'
gem 'net-pop', require: false
gem 'net-sftp'
gem 'net-smtp', require: false
gem 'oj'
gem 'omniauth-cas'
gem 'omniauth-rails_csrf_protection'
gem 'open3'
gem 'orangetheses', github: 'pulibrary/orangetheses', tag: 'v1.4.5'
gem 'pg'
gem 'rack'
gem 'rails', '~> 8.1'
gem 'responders'
gem 'rest-client', require: false
gem 'rsolr', '~> 2.5.0'
gem 'rubyzip'
gem 'sass-rails'
gem 'sidekiq'
gem 'stringex', github: 'pulibrary/stringex', tag: 'vpton.2.5.2.2'
gem 'terser'
gem 'traject'
gem 'turbolinks'
gem 'whenever'
gem 'yard'

group :production do
  gem 'datadog', require: 'datadog/auto_instrument'
end

group :development do
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-rails-console', require: false
  gem 'dotenv-rails'
end

group :development, :test do
  # bundler and rake come in from the voyager_helpers gemspec
  gem 'byebug'
  gem 'coveralls_reborn'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'puma'
  gem 'rails-controller-testing'
  gem 'rspec-benchmark'
  gem 'rubocop'
  gem 'rubocop-factory_bot'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'simplecov'
  gem 'solargraph'
  gem 'solr_wrapper'
  gem 'timecop'
  gem 'webmock'
end

group :test do
  gem 'axe-core-api', require: false
  gem 'axe-core-rspec', require: false
  gem 'rspec-rails'
  gem 'selenium-webdriver'
end

gem 'rake-compiler'
gem 'rb_sys', '~> 0.9.111'
