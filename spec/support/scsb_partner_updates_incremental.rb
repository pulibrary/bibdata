# frozen_string_literal: true

RSpec.shared_context 'scsb_partner_updates_incremental' do
  include_context 'scsb_partner_updates'
  let(:event) { FactoryBot.build(:event) }
  let(:dump) { Dump.create(dump_type: :partner_recap, event_id: event.id) }
  let(:timestamp) { Dump.send(:incremental_update_timestamp) }
  let(:scsb_file) { file_fixture('scsb/scsb_leaderd.xml').to_s }
  before do
    event.save
    allow(s3_bucket).to receive(:list_files)
    FileUtils.cp(Rails.root.join(fixture_paths, 'updates.zip'), update_directory_path.join('CUL-NYPL-HL_20210622_183200.zip'))
    FileUtils.cp(Rails.root.join(fixture_paths, 'deletes.zip'), update_directory_path.join('CUL-NYPL-HL_20210622_183300.zip'))
    allow(s3_bucket).to receive(:download_files).and_return(
      [Rails.root.join(update_directory_path, 'CUL-NYPL-HL_20210622_183200.zip').to_s],
      [Rails.root.join(update_directory_path, 'CUL-NYPL-HL_20210622_183300.zip').to_s]
    )
  end
end
