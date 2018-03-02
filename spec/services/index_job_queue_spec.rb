require 'rails_helper'

RSpec.describe IndexJobQueue, :type => :service do
  subject(:index_job_queue) { described_class.new(config: config, url: url) }
  let(:config) { Rails.application.config.traject['config'] }
  let(:url) { Rails.application.config.solr['url'] }
  let(:file) { Rails.root.join('spec', 'fixtures', '1234567.mrx') }

  describe '.traject_path' do
    it 'accesses the default path to the Traject executable' do
      expect(described_class.traject_path).to eq '/usr/bin/env traject'
    end
  end

  describe '.traject_commit_settings' do
    it 'accesses the default commit settings for Solr' do
      expect(described_class.traject_commit_settings).to eq '--setting solrj_writer.commit_on_close=true'
    end
  end

  describe '#add' do
    let(:index_job) { class_double('IndexJob').as_stubbed_const(transfer_nested_constants: true) }
    before do
      allow(index_job).to receive(:perform_later)
      index_job_queue.add(file: file)
    end
    it 'enqueues an IndexJob to be performed' do
      expect(index_job).to have_received(:perform_later).with(traject: described_class.traject_path, config: config, file: file, url: url, commit: described_class.traject_commit_settings)
    end
    context 'when Solr should not commit after POSTing a single Document' do
      subject(:index_job_queue) { described_class.new(config: config, url: url, commit: false) }
      it 'enqueues an IndexJob to be performed without automatically committing' do
        expect(index_job).to have_received(:perform_later).with(traject: described_class.traject_path, config: config, file: file, url: url, commit: '')
      end
    end
  end
end
