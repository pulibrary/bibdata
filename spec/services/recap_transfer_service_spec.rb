require 'rails_helper'

RSpec.describe RecapTransferService do
  describe ".transfer" do
    before do
      Timecop.freeze(Time.utc(2021, 4, 13, 3, 0, 0))
    end
    after do
      Timecop.return
    end
    it "transfers the given dump file" do
      dump_file = FactoryBot.create(:recap_incremental_dump_file)
      bucket_mock = instance_double(Scsb::S3Bucket)
      allow(Scsb::S3Bucket).to receive(:recap_transfer_client).and_return(bucket_mock)
      allow(bucket_mock).to receive(:upload_file)

      described_class.transfer(file_path: dump_file.path)

      expect(bucket_mock).to have_received(:upload_file).with(file_path: "data/1618282800", key: "1618282800")
    end
  end
end
