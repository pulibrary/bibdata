RSpec.configure do |config|
  # rubocop:disable RSpec/BeforeAfterAll
  # Ideally, we could use config.when_first_matching_example_defined(:indexing) instead,
  # but that fails to load Webmock
  config.before(:all) do
    stub_request(:get, 'https://figgy.princeton.edu/reports/mms_records.json?auth_token=FAKE_TOKEN')
      .to_return(status: 200, body: File.open('spec/fixtures/files/figgy/figgy_report.json'))
    MmsRecordsReport.new.to_translation_map
  end
  # rubocop:enable RSpec/BeforeAfterAll
end
