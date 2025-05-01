require 'rails_helper'

RSpec.describe MmsRecordsReport do
  let(:figgy_request) do
    stub_request(:get, 'https://figgy.princeton.edu/reports/mms_records.json?auth_token=FAKE_TOKEN')
      .to_return(status: 200, body: File.open('spec/fixtures/files/figgy_report.json'))
  end

  before do
    Rails.cache.clear
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('CATALOG_SYNC_TOKEN').and_return('FAKE_TOKEN')
    figgy_request
  end

  it 'knows the mms records report endpoint' do
    expect(described_class.endpoint).to eq('https://figgy.princeton.edu')
  end

  it 'caches the report' do
    described_class.new.mms_records_report
    described_class.new.mms_records_report
    expect(figgy_request).to have_been_requested.once
  end

  context 'with incorrect token' do
    let(:figgy_request) do
      stub_request(:get, 'https://figgy.princeton.edu/reports/mms_records.json?auth_token=FAKE_TOKEN')
        .to_return(status: 403, body: '')
    end

    it 'raises the error' do
      expect do
        described_class.new.mms_records_report
      end.to raise_error(MmsRecordsReport::AuthenticationError, 'Authentication error - check figgy auth_token')
    end
  end
end
