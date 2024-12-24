# frozen_string_literal: true

RSpec.shared_context 'scsb_partner_updates' do
  let(:scsb_file_dir) { Rails.root.join('tmp', 'specs', 'data') }
  let(:update_directory_path) { Rails.root.join('tmp', 'specs', 'update_directory') }
  let(:fixture_paths) { Rails.root.join('spec', 'fixtures', 'scsb_updates') }
  let(:s3_bucket) { instance_double(Scsb::S3Bucket) }

  before do
    FileUtils.rm_rf(scsb_file_dir)
    FileUtils.mkdir_p(scsb_file_dir)

    FileUtils.rm_rf(update_directory_path)
    FileUtils.mkdir_p(update_directory_path)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('SCSB_FILE_DIR').and_return(scsb_file_dir)
    allow(ENV).to receive(:[]).with('SCSB_PARTNER_UPDATE_DIRECTORY').and_return(update_directory_path)
    allow(Scsb::S3Bucket).to receive(:partner_transfer_client).and_return(s3_bucket)
  end
end
