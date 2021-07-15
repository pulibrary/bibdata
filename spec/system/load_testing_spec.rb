# frozen_string_literal: true

require 'rails_helper'

describe 'Load Testing', type: :system, js: true do
  let(:siege_file) do
    Tempfile.new('siege.json')
  end
  let(:solr_connection_config) do
    Rails.application.config.solr
  end
  let(:solr_url) do
    solr_connection_config['url']
  end
  let(:siege_report) do
    JSON.parse(siege_file.read)
  end
  let(:siege_time) do
    10
  end
  let(:document_id) { '99121886293506421' }
  let(:target_uri) { "#{page.server.base_url}/bibliographic/#{document_id}" }

  before do
    stub_alma_ids(ids: document_id, status: 200)

    visit "/bibliographic/#{document_id}"
    system("/usr/bin/env siege --internet --concurrent=5 --time=#{siege_time}S --json-output #{target_uri} > #{siege_file.path}")
  end

  after do
    siege_file.close
    siege_file.unlink
  end

  it 'supports requesting the XML representation of bibliographic records' do
    expect(siege_report).to include("successful_transactions")
    expect(siege_report["successful_transactions"]).to be > 0
    expect(siege_report).to include("failed_transactions")
    expect(siege_report["failed_transactions"]).to be <= 0
  end

  context 'when requesting the Solr Document transformations of bibliographic records' do
    let(:target_uri) { "#{page.server.base_url}/bibliographic/#{document_id}/solr" }

    it 'supports requesting bibliographic records' do
      expect(siege_report).to include("successful_transactions")
      expect(siege_report["successful_transactions"]).to be > 0
      expect(siege_report).to include("failed_transactions")
      expect(siege_report["failed_transactions"]).to be <= 0
    end
  end

  context 'when requesting JSON-LD representations of bibliographic records' do
    let(:target_uri) { "#{page.server.base_url}/bibliographic/#{document_id}/jsonld" }

    it 'supports requesting bibliographic records' do
      expect(siege_report).to include("successful_transactions")
      expect(siege_report["successful_transactions"]).to be > 0
      expect(siege_report).to include("failed_transactions")
      expect(siege_report["failed_transactions"]).to be <= 0
    end
  end
end
