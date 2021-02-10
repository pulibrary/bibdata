require 'rails_helper'

RSpec.describe Scsb::S3Bucket, type: :model do
  let(:s3_credentials) { instance_double("Aws::Credentials") }
  let(:s3_client) { Aws::S3::Client.new(region: 'us-east-1', credentials: s3_credentials) }
  let(:s3) { described_class.new(s3_client: s3_client, s3_bucket_name: 'test') }

  describe "list_files" do
    it "returns the objects" do
      allow(s3_client).to receive(:list_objects).with(bucket: 'test', prefix: 'prefix', delimiter: '').and_return(Aws::S3::Types::ListObjectsOutput.new(contents: Aws::Xml::DefaultList.new))
      results = s3.list_files(prefix: 'prefix')
      expect(results).to be_a(Aws::Xml::DefaultList)
      expect(results.size).to eq(0)
    end
  end

  describe "download_file" do
    it "returns the content" do
      output = Aws::S3::Types::GetObjectOutput.new(body: StringIO.new)
      allow(s3_client).to receive(:get_object).with(bucket: 'test', key: 'abc/123').and_return(output)
      results = s3.download_file(key: 'abc/123')
      expect(results).to be_a(StringIO)
    end
  end

  describe "upload_file" do
    it "returns true when the file uploads" do
      output = Aws::S3::Types::PutObjectOutput.new
      allow(s3_client).to receive(:put_object).with(bucket: 'test', key: 'data-feed/submitcollections/PUL/cgd_protection/scsb_abc_123', body: kind_of(File)).and_return(output)
      results = s3.upload_file(key: 'abc_123', file_path: Rails.root.join('spec', 'fixtures', '10002695.mrx'))
      expect(results).to be_truthy
    end

    context "an error occurs" do
      it "returns false when the does not file upload" do
        allow(s3_client).to receive(:put_object).with(bucket: 'test', key: 'data-feed/submitcollections/PUL/cgd_protection/scsb_abc_123', body: kind_of(File)).and_raise(Aws::S3::Errors::AccessDenied.new(nil, "access denied"))
        results = s3.upload_file(key: 'abc_123', file_path: Rails.root.join('spec', 'fixtures', '10002695.mrx'))
        expect(results).to be_falsey
      end
    end
  end

  describe "download_files" do
    it "returns the content" do
      files = [Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_1.zip", last_modified: 1.day.ago),
               Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_2.zip", last_modified: 2.days.ago),
               Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_3.zip", last_modified: 1.week.ago),
               Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_3.csv", last_modified: 1.day.ago)]
      output1 = Aws::S3::Types::GetObjectOutput.new(body: StringIO.new("abc123"))
      output2 = Aws::S3::Types::GetObjectOutput.new(body: StringIO.new("def456"))
      allow(s3_client).to receive(:get_object).with(bucket: 'test', key: 'exports/ABC/MARCXml/Full/NYPL_1.zip').and_return(output1)
      allow(s3_client).to receive(:get_object).with(bucket: 'test', key: 'exports/ABC/MARCXml/Full/NYPL_2.zip').and_return(output2)
      path = '/tmp/s3_bucket_test'
      FileUtils.rm_rf(path)
      Dir.mkdir(path)
      s3.download_files(files: files, timestamp_filter: 3.days.ago, output_directory: path, file_filter: /NYPL.*\.zip/)
      expect(Dir.entries(path)).to contain_exactly(".", "..", "NYPL_2.zip", "NYPL_1.zip")
    end
  end
end
