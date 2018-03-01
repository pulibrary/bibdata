require 'rails_helper'

RSpec.describe IndexJob, type: :job do
  subject(:index_job) { described_class.new }
  let(:traject) { '/usr/bin/env traject' }
  let(:config) { Rails.application.config.traject['config'] }
  let(:file) { Rails.root.join('spec', 'fixtures', '1234567.mrx') }
  let(:url) { Rails.application.config.solr['url'] }
  let(:commit) { '--setting solrj_writer.commit_on_close=true' }

  describe '.perform' do
    let(:open3) { class_double('Open3').as_stubbed_const(transfer_nested_constants: true) }
    let(:in_stream) { instance_double(IO) }
    let(:out_stream) { instance_double(IO) }
    let(:error_stream) { instance_double(IO) }
    let(:wait_thr) { instance_double(Process::Status) }
    before do
      allow(open3).to receive(:popen3).and_return([in_stream, out_stream, error_stream, wait_thr])
      allow(wait_thr).to receive(:pid).and_return(1234)

      index_job.perform(traject: traject, config: config, file: file, url: url, commit: commit)
    end

    it 'invokes Traject within the shell and POSTs to Solr' do
      expect(open3).to have_received(:popen3).with("#{traject} --conf #{config} --solr #{url} --setting solrj_writer.commit_on_close=true #{file}")
    end

    context 'when Solr should not commit after POSTing a single Document' do
      let(:commit) { '' }
      it 'invokes Traject within the shell and POSTs to Solr without automatically committing' do
        expect(open3).to have_received(:popen3).with("#{traject} --conf #{config} --solr #{url}  #{file}")
      end
    end
  end
end
