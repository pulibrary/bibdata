RSpec.configure do |config|
  config.when_first_matching_example_defined(:indexing) do
    BibdataRs::Marc.index_test_figgy_data_into_redis
  end
end
