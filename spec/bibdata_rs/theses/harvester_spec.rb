# frozen_string_literal: true

require 'spec_helper'

describe 'BibdataRs::Theses::Harvester' do
  subject(:harvester) do
    BibdataRs::Theses::Harvester.new(
      dir:
    )
  end

  let(:dir) { Dir.mktmpdir }
  let(:another_server) { 'http://example.edu/oai/' }
  let(:indexer) do
    instance_double(Orangetheses::Indexer)
  end

  before do
    allow(indexer).to receive(:index)
  end

  describe '#index_item' do
    let(:identifier) { 'oai:dataspace.princeton.edu:88435/dsp012z10wq21r' }
    let(:record_fixture_file) { File.read(file_fixture('theses/oai/record.xml')) }
    let(:record_document) { Nokogiri::XML.parse(record_fixture_file) }
    let(:metadata) { record_document.at_xpath('//oai:metadata', 'oai' => 'http://www.openarchives.org/OAI/2.0/') }
    let(:record) { instance_double(OAI::Record) }
    let(:record_response) { instance_double(OAI::GetRecordResponse) }
    let(:client) { instance_double(OAI::Client) }

    before do
      allow(record).to receive(:metadata).and_return(metadata)
      allow(record_response).to receive(:record).and_return(record)
      allow(client).to receive(:get_record).and_return(record_response)
      allow(OAI::Client).to receive(:new).and_return(client)
    end

    it 'indexes an Item by record identifier' do
      harvester.index_item(indexer:, identifier:)

      expect(indexer).to have_received(:index).with(metadata)
    end
  end

  describe '#_client' do
    let(:headers) { subject.instance_variable_get('@headers') }
    let(:base) { subject.instance_variable_get('@base') }

    describe 'defaults' do
      subject { BibdataRs::Theses::Harvester.new.send(:client) }

      it 'get set for the client' do
        expect(base.to_s).to eq('https://dataspace.princeton.edu/oai/request')
      end
    end

    describe 'overriding defaults' do
      subject { BibdataRs::Theses::Harvester.new(server: another_server).send(:client) }

      it "changes the client's params" do
        expect(base.to_s).to eq another_server
      end
    end
  end
end
