require 'rails_helper'

RSpec.describe AlmaFullDumpTransferJob, type: :job do
  let(:job_id ) { "1436402400006421" }
  let(:name) do
    Net::SFTP::Protocol::V01::Name.new(
      "fulldump_1436402400006421_20201218_211210[050]_new_1.tar.gz",
      "-rw-rw-r--. 1 alma alma  49546443 Dec 18 16:50 fulldump_1436402400006421_20201218_211210[050]_new_1.tar.gz",
      attrs
    )
  end
  let(:remote_path) { "/home/alma/fulldump_1436402400006421_20201218_211210[050]_new_1.tar.gz" }
  let(:attrs) { Net::SFTP::Protocol::V01::Attributes.new({}) }
  # let(:name2) do
  #   Net::SFTP::Protocol::V01::Name.new(
  #     "fulldump_1436402400006421_20201218_211210[050]_new_2.tar.gz",
  #     "-rw-rw-r--. 1 alma alma   4916786 Dec 18 16:50 fulldump_1436402400006421_20201218_211210[050]_new_2.tar.gz",
  #   )
  # end
  let(:name2) do
    Net::SFTP::Protocol::V01::Name.new(
      "fulldump_1434819190006421_2020121520_new_1.xml.tar.gz",
      "-rw-rw-r--. 1 alma alma  49970147 Dec 15 15:55 fulldump_1434819190006421_2020121520_new_1.xml.tar.gz",
      attrs
    )
  end

  describe 'perform' do
    it 'downloads a file' do
      session_stub = instance_double(Net::SFTP::Session)
      dir_stub = instance_double(Net::SFTP::Operations::Dir)
      download_stub = instance_double(Net::SFTP::Operations::Download)
      allow(Net::SFTP).to receive(:start).and_yield(session_stub)
      allow(session_stub).to receive(:dir).and_return(dir_stub)
      allow(dir_stub).to receive(:entries).and_return([name])
      allow(session_stub).to receive(:download).and_return(download_stub)
      allow(download_stub).to receive(:wait)
      dump = FactoryBot.create(:empty_dump)
      described_class.perform_now(dump: dump, job_id: job_id)
      local_path = DumpFile.all.first.path
      puts local_path
      expect(session_stub).to have_received(:download).once.with(remote_path, local_path)
    end
  end

  describe 'remote_paths' do
    it "gets the config value" do
      session_stub = instance_double(Net::SFTP::Session)
      dir_stub = instance_double(Net::SFTP::Operations::Dir)
      allow(session_stub).to receive(:dir).and_return(dir_stub)
      allow(dir_stub).to receive(:entries).and_return([name, name2])
      paths = described_class.new.remote_paths(job_id: job_id, sftp_session: session_stub)
      expect(paths).to eq [remote_path]
    end
  end
end
