require 'rails_helper'

RSpec.describe Import::Alma, type: :job do
  let(:attrs) { Net::SFTP::Protocol::V01::Attributes.new({}) }

  describe 'perform' do
    around do |example|
      Sidekiq::Testing.inline! do
        example.run
      end
    end

    before do
      allow(Index::RemainingDumpsJob).to receive(:perform_async)
    end

    after do
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
    end

    context 'with a full dump' do
      let(:job_id) { '1436402400006421' }

      let(:filename_one) { 'fulldump_1436402400006421_20201218_211210[050]_new_1.tar.gz' }
      let(:name_one) do
        Net::SFTP::Protocol::V01::Name.new(
          filename_one,
          "-rw-rw-r--. 1 alma alma  49546443 Dec 18 16:50 #{filename_one}",
          attrs
        )
      end
      let(:remote_path_one) { "/alma/publishing/#{filename_one}" }
      let(:local_path_one) { File.join(MARC_LIBERATION_CONFIG['data_dir'], filename_one) }

      let(:filename_two) { 'fulldump_1436402400006421_20201218_211210[050]_new_2.tar.gz' }
      let(:name_two) do
        Net::SFTP::Protocol::V01::Name.new(
          filename_two,
          "-rw-rw-r--. 1 alma alma   4916786 Dec 18 16:50 #{filename_two}",
          attrs
        )
      end
      let(:remote_path_two) { "/alma/publishing/#{filename_two}" }
      let(:local_path_two) { File.join(MARC_LIBERATION_CONFIG['data_dir'], filename_two) }

      let(:filename_three) { 'fulldump_1434819190006421_2020121520_new_1.xml.tar.gz' }
      let(:name_three) do
        Net::SFTP::Protocol::V01::Name.new(
          filename_three,
          "-rw-rw-r--. 1 alma alma  49970147 Dec 15 15:55 #{filename_three}",
          attrs
        )
      end

      let(:dump) do
        create(:empty_dump).tap do |d|
          d.event.message_body = '{"job_instance": {"name":"Publishing Platform Job General Publishing"}}'
          d.event.save
        end
      end
      let(:session_stub) { instance_double(Net::SFTP::Session) }
      let(:dir_stub) { instance_double(Net::SFTP::Operations::Dir) }
      let(:download_stub) { instance_double(Net::SFTP::Operations::Download) }

      before do
        allow(Net::SFTP).to receive(:start).and_yield(session_stub)
        allow(dir_stub).to receive(:entries).and_return([name_one, name_two, name_three])
        allow(session_stub).to receive_messages(dir: dir_stub, download: download_stub)
        allow(download_stub).to receive(:wait)
      end

      it 'downloads the files' do
        described_class.perform_async(dump.id, job_id)

        expect(session_stub).to have_received(:download).once.with(remote_path_one, local_path_one)
        expect(session_stub).to have_received(:download).once.with(remote_path_two, local_path_two)
        expect(Dump.count).to eq 1

        expect(dump.dump_files.count).to eq 2
        expect(dump.dump_files.map(&:dump_file_type).uniq).to eq ['bib_records']
        expect(dump.dump_files.map(&:path)).to contain_exactly(File.join(MARC_LIBERATION_CONFIG['data_dir'], filename_one), File.join(MARC_LIBERATION_CONFIG['data_dir'], filename_two))

        expect(Index::RemainingDumpsJob).not_to have_received(:perform_async)
      end
    end

    context 'with an incremental dump' do
      let(:job_id) { '6587815790006421' }
      let(:filename) { 'incremental_6587815790006421_20210208_200239[040]_new.tar.gz' }
      let(:name) do
        Net::SFTP::Protocol::V01::Name.new(
          filename,
          "-rw-rw-r--    1 alma     alma        10342 Feb  8 15:40 #{filename}",
          attrs
        )
      end
      let(:remote_path) { "/alma/publishing/#{filename}" }
      let(:local_path) { File.join(MARC_LIBERATION_CONFIG['data_dir'], filename) }
      let(:dump) do
        create(:empty_incremental_dump).tap do |d|
          d.event.message_body = '{"job_instance": {"name":"Publishing Platform Job Incremental Publishing"}}'
          d.event.save
        end
      end

      it 'downloads the file' do
        session_stub = instance_double(Net::SFTP::Session)
        dir_stub = instance_double(Net::SFTP::Operations::Dir)
        download_stub = instance_double(Net::SFTP::Operations::Download)
        allow(Net::SFTP).to receive(:start).and_yield(session_stub)
        allow(dir_stub).to receive(:entries).and_return([name])
        allow(session_stub).to receive_messages(dir: dir_stub, download: download_stub)
        allow(download_stub).to receive(:wait)

        described_class.perform_async(dump.id, job_id)

        expect(session_stub).to have_received(:download).once.with(remote_path, local_path)
        expect(Dump.count).to eq 1
        expect(Dump.first.dump_files.count).to eq 1
        expect(Dump.first.dump_files.map(&:dump_file_type).uniq).to eq ['updated_records']
        expect(Dump.first.dump_files.first.path).to eq File.join(MARC_LIBERATION_CONFIG['data_dir'], filename)
        expect(Index::RemainingDumpsJob).to have_received(:perform_async).once
      end
    end
  end
end
