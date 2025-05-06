RSpec.configure do |config|
  config.when_first_matching_example_defined(:rust) do
    Rails.application.load_tasks
    Rake::Task['compile'].invoke
  end
end
