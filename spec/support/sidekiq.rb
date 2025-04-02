RSpec.configure do |config|
  config.when_first_matching_example_defined(:sidekiq, type: :job) { require 'sidekiq/testing' }
end
