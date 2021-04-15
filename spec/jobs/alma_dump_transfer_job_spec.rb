require 'rails_helper'

RSpec.describe AlmaDumpTransferJob, type: :job do
  let(:attrs) { Net::SFTP::Protocol::V01::Attributes.new({}) }

  describe 'perform' do
    after do
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
    end

    context "with a full dump" do
      let(:job_id) { "1436402400006421" }

      let(:filename1) { "fulldump_1436402400006421_20201218_211210[050]_new_1.tar.gz" }
      let(:name1) do
        Net::SFTP::Protocol::V01::Name.new(
          filename1,
          "-rw-rw-r--. 1 alma alma  49546443 Dec 18 16:50 #{filename1}",
          attrs
        )
      end
      let(:remote_path1) { "/alma/publishing/#{filename1}" }
      let(:local_path1) { File.join(MARC_LIBERATION_CONFIG['data_dir'], filename1) }

      let(:filename2) { "fulldump_1436402400006421_20201218_211210[050]_new_2.tar.gz" }
      let(:name2) do
        Net::SFTP::Protocol::V01::Name.new(
          filename2,
          "-rw-rw-r--. 1 alma alma   4916786 Dec 18 16:50 #{filename2}",
          attrs
        )
      end
      let(:remote_path2) { "/alma/publishing/#{filename2}" }
      let(:local_path2) { File.join(MARC_LIBERATION_CONFIG['data_dir'], filename2) }

      let(:filename3) { "fulldump_1434819190006421_2020121520_new_1.xml.tar.gz" }
      let(:name3) do
        Net::SFTP::Protocol::V01::Name.new(
          filename3,
          "-rw-rw-r--. 1 alma alma  49970147 Dec 15 15:55 #{filename3}",
          attrs
        )
      end

      let(:dump) do
        FactoryBot.create(:empty_dump).tap do |d|
          d.event.message_body = "{\"job_instance\": {\"name\":\"Publishing Platform Job General Publishing via FTP\"}}"
          d.event.save
        end
      end

      before do
        FactoryBot.create(:full_dump_file_type)
      end

      it 'downloads the files' do
        session_stub = instance_double(Net::SFTP::Session)
        dir_stub = instance_double(Net::SFTP::Operations::Dir)
        download_stub = instance_double(Net::SFTP::Operations::Download)
        allow(Net::SFTP).to receive(:start).and_yield(session_stub)
        allow(session_stub).to receive(:dir).and_return(dir_stub)
        allow(dir_stub).to receive(:entries).and_return([name1, name2, name3])
        allow(session_stub).to receive(:download).and_return(download_stub)
        allow(download_stub).to receive(:wait)
        described_class.perform_now(dump: dump, job_id: job_id)
        expect(session_stub).to have_received(:download).once.with(remote_path1, local_path1)
        expect(session_stub).to have_received(:download).once.with(remote_path2, local_path2)
        expect(Dump.all.count).to eq 1
        expect(Dump.first.dump_files.count).to eq 2
        expect(Dump.first.dump_files.map(&:dump_file_type).map(&:constant).uniq).to eq ["BIB_RECORDS"]
        expect(Dump.first.dump_files.first.path).to eq File.join(MARC_LIBERATION_CONFIG['data_dir'], filename1)
        expect(IncrementalIndexJob).not_to have_been_enqueued
      end
    end

    context "with an incremental dump" do
      let(:job_id) { "6587815790006421" }
      let(:filename) { "incremental_6587815790006421_20210208_200239[040]_new.tar.gz" }
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
        FactoryBot.create(:empty_incremental_dump).tap do |d|
          d.event.message_body = "{\"job_instance\": {\"name\":\"Publishing Platform Job Incremental Publishing via FTP\"}}"
          d.event.save
        end
      end

      before do
        FactoryBot.create(:incremental_dump_file_type)
      end

      it 'downloads the file' do
        session_stub = instance_double(Net::SFTP::Session)
        dir_stub = instance_double(Net::SFTP::Operations::Dir)
        download_stub = instance_double(Net::SFTP::Operations::Download)
        allow(Net::SFTP).to receive(:start).and_yield(session_stub)
        allow(session_stub).to receive(:dir).and_return(dir_stub)
        allow(dir_stub).to receive(:entries).and_return([name])
        allow(session_stub).to receive(:download).and_return(download_stub)
        allow(download_stub).to receive(:wait)

        described_class.perform_now(dump: dump, job_id: job_id)

        expect(session_stub).to have_received(:download).once.with(remote_path, local_path)
        expect(Dump.all.count).to eq 1
        expect(Dump.first.dump_files.count).to eq 1
        expect(Dump.first.dump_files.map(&:dump_file_type).map(&:constant).uniq).to eq ["UPDATED_RECORDS"]
        expect(Dump.first.dump_files.first.path).to eq File.join(MARC_LIBERATION_CONFIG['data_dir'], filename)
        expect(IncrementalIndexJob).to have_been_enqueued.once
      end
    end
    context "with a recap incremental dump" do
      let(:job_id) { "6836725000006421" }
      let(:filename) { "recap_6836725000006421_20210401_010420[012]_new_1.xml.tar.gz" }
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
        FactoryBot.create(:empty_recap_incremental_dump).tap do |d|
          d.event.message_body = "{\"job_instance\": {\"name\":\"Publishing Platform Job Incremental ReCAP Records\"}}"
          d.event.save
        end
      end

      before do
        FactoryBot.create(:recap_incremental_dump_file_type)
      end

      it 'downloads the file' do
        session_stub = instance_double(Net::SFTP::Session)
        dir_stub = instance_double(Net::SFTP::Operations::Dir)
        download_stub = instance_double(Net::SFTP::Operations::Download)
        allow(Net::SFTP).to receive(:start).and_yield(session_stub)
        allow(session_stub).to receive(:dir).and_return(dir_stub)
        allow(dir_stub).to receive(:entries).and_return([name])
        allow(session_stub).to receive(:download).and_return(download_stub)
        allow(download_stub).to receive(:wait)

        described_class.perform_now(dump: dump, job_id: job_id)

        expect(session_stub).to have_received(:download).once.with(remote_path, local_path)
        expect(Dump.all.count).to eq 1
        expect(Dump.first.dump_files.count).to eq 1
        expect(Dump.first.dump_files.map(&:dump_file_type).map(&:constant).uniq).to eq ["RECAP_RECORDS"]
        first_dump_file = Dump.first.dump_files.first
        expect(first_dump_file.path).to eq File.join(MARC_LIBERATION_CONFIG['data_dir'], filename)

        # Ensure job is queued.
        expect(RecapDumpFileProcessingJob).to have_been_enqueued.once
      end
    end
  end
end
