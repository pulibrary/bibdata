require 'rails_helper'

RSpec.describe AlmaFullDumpTransferJob, type: :job do
  describe 'perform' do
    it 'downloads a file' do
      job_id = "1395961390006421"
      attrs = Net::SFTP::Protocol::V01::Attributes.new({})
      name = Net::SFTP::Protocol::V01::Name.new(
        "fulldump_1395961390006421_2020070215_new_1",
        "-rw-rw-r--    1 alma     alma     152135326 Jul  2 11:10 fulldump_1395961390006421_2020070215_new_1",
        attrs
      )
      remote_path = "/home/alma/fulldump_1395961390006421_2020070215_new_1"
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
      expect(session_stub).to have_received(:download).once.with(remote_path, local_path)
    end
  end

  describe 'remote_paths' do
    it "gets the config value" do
      job_id = "1395961390006421"
      attrs = Net::SFTP::Protocol::V01::Attributes.new({})
      name = Net::SFTP::Protocol::V01::Name.new(
        "fulldump_1395961390006421_2020070215_new_1",
        "-rw-rw-r--    1 alma     alma     152135326 Jul  2 11:10 fulldump_1395961390006421_2020070215_new_1",
        attrs
      )
      name2 = Net::SFTP::Protocol::V01::Name.new(
        "fulldump_1434818870006421_2020121520_new_1",
        "-rw-rw-r--    1 alma     alma     152135326 Jul  2 11:10 fulldump_1434818870006421_2020121520_new_1",
        attrs
      )
      session_stub = instance_double(Net::SFTP::Session)
      dir_stub = instance_double(Net::SFTP::Operations::Dir)
      allow(session_stub).to receive(:dir).and_return(dir_stub)
      allow(dir_stub).to receive(:entries).and_return([name, name2])
      paths = described_class.new.remote_paths(job_id: job_id, sftp_session: session_stub)
      expect(paths).to eq ["/home/alma/fulldump_1395961390006421_2020070215_new_1"]
    end
  end
end
