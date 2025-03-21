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
  end
end

require 'webmock/rspec'
require 'traject'
require 'support/required_environments'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
