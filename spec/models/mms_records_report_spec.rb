require 'rails_helper'

RSpec.describe MmsRecordsReport do
  let(:figgy_request) do
    stub_request(:get, 'https://figgy.princeton.edu/reports/mms_records.json?auth_token=FAKE_TOKEN')
      .to_return(status: 200, body: File.open('spec/fixtures/files/figgy/figgy_report.json'))
  end

  before do
    Rails.cache.clear
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('CATALOG_SYNC_TOKEN', 'FAKE_TOKEN').and_return('FAKE_TOKEN')
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

  context 'saving as a translation map' do
    let(:translation_map_path) { 'spec/fixtures/files/figgy/translation_map.yml' }

    around do |example|
      FileUtils.rm_f(translation_map_path)
      example.run
      FileUtils.rm_f(translation_map_path)
    end

    it 'saves it to a ruby file as a translation map' do
      expect(File.exist?(translation_map_path)).to be false
      described_class.new.to_translation_map(translation_map_path:)
      expect(File.exist?(translation_map_path)).to be true
    end

    it 'only includes public items' do
      described_class.new.to_translation_map(translation_map_path:)
      translation_map = YAML.load_file(translation_map_path)
      expect(translation_map.keys).not_to include('99129146648906421')
      expect(translation_map.keys.size).to eq(7)
    end

    context 'a generally open record with a private item' do
      it 'only maps the open items' do
        described_class.new.to_translation_map(translation_map_path:)
        translation_map = YAML.load_file(translation_map_path)
        expect(translation_map['9954388673506421'].size).to eq(78)
      end
    end
  end
end
