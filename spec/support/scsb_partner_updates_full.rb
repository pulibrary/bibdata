# frozen_string_literal: true

RSpec.shared_context 'scsb_partner_updates_full' do
  include_context 'scsb_partner_updates'

  let!(:event) { Event.create(dump:) }
  let(:dump) { Dump.create(dump_type: :partner_recap_full) }
  let(:partner_full_update) { described_class.new(dump:, dump_file_type: :recap_records_full) }
  let(:cul_zip) { 'CUL_20210429_192300.zip' }
  let(:cul_csv) { 'ExportDataDump_Full_CUL_20210429_192300.csv' }
  let(:nypl_zip) { 'NYPL_20210430_015000.zip' }
  let(:nypl_csv) { 'ExportDataDump_Full_NYPL_20210430_015000.csv' }
  let(:hl_zip) { 'HL_20210716_063500.zip' }
  let(:hl_csv) { 'ExportDataDump_Full_HL_20210716_063500.csv' }
  let(:fixture_files) { [cul_zip, cul_csv, nypl_zip, nypl_csv, hl_zip, hl_csv] }
  let(:filter_response_pairs) do
    [
      [/CUL.*\.zip/, Rails.root.join(update_directory_path, cul_zip)],
      [/CUL.*\.csv/, Rails.root.join(update_directory_path, cul_csv)],
      [/NYPL.*\.zip/, Rails.root.join(update_directory_path, nypl_zip)],
      [/NYPL.*\.csv/, Rails.root.join(update_directory_path, nypl_csv)],
      [/HL.*\.zip/, Rails.root.join(update_directory_path, hl_zip)],
      [/HL.*\.csv/, Rails.root.join(update_directory_path, hl_csv)]
    ]
  end
  before do
    # Copy the fixtures to the temporary location for the tests
    fixture_files.each do |path|
      FileUtils.cp(Rails.root.join(fixture_paths, path), update_directory_path)
    end
    # Mock the remote S3 bucket interaction
    filter_response_pairs.each do |filter, response|
      allow(s3_bucket).to receive(:download_recent)
        .with(hash_including(file_filter: filter))
        .and_return(response)
    end
  end
end
