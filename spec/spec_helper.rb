
require 'simplecov'
require 'coveralls'
require 'webmock/rspec'
require 'traject'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
)
SimpleCov.start('rails') do
  add_filter '/spec'
end
