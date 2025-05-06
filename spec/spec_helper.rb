def in_ci?
  ENV.fetch('CI', nil) == 'true'
end

if in_ci?
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  )
  SimpleCov.start('rails') do
    add_filter '/spec'
    add_filter '/lib/tasks'
  end
end

require 'webmock/rspec'
require 'traject'
require 'support/required_environments'
require File.expand_path('../marc_to_solr/lib', __dir__)

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(File.expand_path('../marc_to_solr', __dir__))
