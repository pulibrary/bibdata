require 'rails_helper'
require 'rspec-benchmark'

RSpec.describe Import::Partner::ProcessXmlFileJob do
  include RSpec::Benchmark::Matchers
  include_context 'scsb_partner_updates_full'
  around do |example|
    Sidekiq::Testing.inline! do
      example.run
    end
  end

  before do
    # Don't delete our fixture files
    allow(File).to receive(:unlink)
  end

  let(:large_xml_file) { Rails.root.join('spec/fixtures/scsb_updates/several_records.xml').to_s }

  it 'is reasonably performant' do
    expect do
      described_class.perform_async(dump.id, large_xml_file)
    end.to perform_under(75).ms.sample(10).times
  end
end
