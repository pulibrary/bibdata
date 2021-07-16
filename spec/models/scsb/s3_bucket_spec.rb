require 'rails_helper'

RSpec.describe Scsb::S3Bucket, type: :model do
  let(:s3_credentials) { instance_double("Aws::Credentials") }
  let(:s3_client) { Aws::S3::Client.new(region: 'us-east-1', credentials: s3_credentials) }
  let(:s3) { described_class.new(s3_client: s3_client, s3_bucket_name: 'test') }

  describe ".recap_transfer_client" do
    it "uses SCSB_S3 keys" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SCSB_S3_BUCKET_NAME").and_return("stuff")
      bucket = described_class.recap_transfer_client

      expect(bucket.s3_bucket_name).to eq "stuff"
    end
  end

  describe ".partner_transfer_client" do
    it "uses SCSB_S3_PARTNER keys" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SCSB_S3_PARTNER_BUCKET_NAME").and_return("otherstuff")
      bucket = described_class.partner_transfer_client

      expect(bucket.s3_bucket_name).to eq "otherstuff"
    end
  end

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
      results = s3.upload_file(key: 'abc_123', file_path: Rails.root.join('spec', 'fixtures', '99100026953506421.mrx'))
      expect(results).to be_truthy
    end

    context "an error occurs" do
      it "returns false when the does not file upload" do
        allow(s3_client).to receive(:put_object).with(bucket: 'test', key: 'data-feed/submitcollections/PUL/cgd_protection/scsb_abc_123', body: kind_of(File)).and_raise(Aws::S3::Errors::AccessDenied.new(nil, "access denied"))
        results = s3.upload_file(key: 'abc_123', file_path: Rails.root.join('spec', 'fixtures', '99100026953506421.mrx'))
        expect(results).to be_falsey
      end
    end
  end

  describe "download_files" do
    it "downloads the content and returns the location of the downloaded files" do
      files = [Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_1.zip", last_modified: 1.day.ago),
               Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_2.zip", last_modified: 2.days.ago),
               Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_3.zip", last_modified: 1.week.ago),
               Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_3.csv", last_modified: 1.day.ago)]
      output1 = Aws::S3::Types::GetObjectOutput.new(body: StringIO.new("abc123"))
      output2 = Aws::S3::Types::GetObjectOutput.new(body: StringIO.new("def456"))
      allow(s3_client).to receive(:get_object).with(bucket: 'test', key: 'exports/ABC/MARCXml/Full/NYPL_1.zip').and_return(output1)
      allow(s3_client).to receive(:get_object).with(bucket: 'test', key: 'exports/ABC/MARCXml/Full/NYPL_2.zip').and_return(output2)
      path = Rails.root.join('tmp', 's3_bucket_test')
      FileUtils.rm_rf(path)
      Dir.mkdir(path)
      locations = s3.download_files(files: files, timestamp_filter: 3.days.ago, output_directory: path, file_filter: /NYPL.*\.zip/)
      expect(Dir.entries(path)).to contain_exactly(".", "..", "NYPL_2.zip", "NYPL_1.zip")
      expect(locations).to contain_exactly(File.join(path, "NYPL_1.zip"), File.join(path, "NYPL_2.zip"))
    end
  end

  describe "download_recent" do
    it "downloads the most recent file matching the filter and returns the location of the downloaded file" do
      files = [
        Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/CUL_1.zip", last_modified: Time.new(1.day.ago.to_i)),
        Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/CUL_1.csv", last_modified: Time.new(1.day.ago.to_i)),
        Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_1.zip", last_modified: Time.new(1.day.ago.to_i)),
        Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/CUL_2.zip", last_modified: Time.new(2.days.ago.to_i)),
        Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/CUL_3.zip", last_modified: Time.new(1.week.ago.to_i))
      ]
      aws_list = Aws::S3::Types::ListObjectsOutput.new(contents: Aws::Xml::DefaultList.new(files))

      allow(s3_client).to receive(:list_objects).with(bucket: 'test', prefix: 'prefix', delimiter: '').and_return(aws_list)

      output1 = Aws::S3::Types::GetObjectOutput.new(body: StringIO.new("abc123"))
      allow(s3_client).to receive(:get_object).with(bucket: 'test', key: 'exports/ABC/MARCXml/Full/CUL_1.zip').and_return(output1)
      path = Rails.root.join('tmp', 's3_bucket_test')
      FileUtils.rm_rf(path)
      Dir.mkdir(path)

      location = s3.download_recent(prefix: 'prefix', output_directory: path, file_filter: /CUL.*\.zip/)
      expect(Dir.entries(path)).to contain_exactly(".", "..", "CUL_1.zip")
      expect(location).to eq File.join(path, "CUL_1.zip")
    end

    it "returns nil if no file matching filter is found" do
      files = [
        Aws::S3::Types::Object.new(key: "exports/ABC/MARCXml/Full/NYPL_1.zip", last_modified: Time.new(1.day.ago.to_i))
      ]
      aws_list = Aws::S3::Types::ListObjectsOutput.new(contents: Aws::Xml::DefaultList.new(files))

      allow(s3_client).to receive(:list_objects).with(bucket: 'test', prefix: 'prefix', delimiter: '').and_return(aws_list)

      path = Rails.root.join('tmp', 's3_bucket_test')
      FileUtils.rm_rf(path)
      Dir.mkdir(path)

      location = s3.download_recent(prefix: 'prefix', output_directory: path, file_filter: /CUL.*\.zip/)
      expect(Dir.entries(path)).to contain_exactly(".", "..")
      expect(location).to eq nil
    end
  end
end
