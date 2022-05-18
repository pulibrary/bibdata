require 'rails_helper'

RSpec.describe Dump, type: :model do
  let(:partner_recap) { 'PARTNER_RECAP' }
  let(:princeton_recap) { 'PRINCETON_RECAP' }
  let(:partner_recap_full) { 'PARTNER_RECAP_FULL' }
  let(:princeton_recap_dump_type) { DumpType.find_by(constant: princeton_recap) }
  let(:partner_recap_dump_type) { DumpType.find_by(constant: partner_recap) }
  let(:partner_recap_full_dump_type) { DumpType.find_by(constant: partner_recap_full) }
  let(:test_create_time) { '2017-04-29 20:10:29'.to_time }
  let(:event_success) { Event.create(start: '2020-10-20 19:00:15', finish: '2020-10-20 19:00:41', error: nil, success: true, created_at: "2020-10-20 19:00:41", updated_at: "2020-10-20 19:00:41") }
  let(:dump_princeton_recap_success) { described_class.create(event_id: event_success.id, dump_type_id: princeton_recap_dump_type.id, created_at: "2020-10-20 19:00:15", updated_at: "2020-10-20 19:00:41") }

  describe ".partner_recap" do
    it "is a scope that can chain" do
      FactoryBot.create(:empty_partner_recap_dump)
      dumps = described_class.partner_recap.where(created_at: 4.hours.ago..Time.now)
      expect(dumps.count).to eq 1
    end
  end

  describe ".partner_update" do
    context "when there's no previous partner recap dump" do
      it "creates a dump using the current time and imports SCSB partner records into it" do
        frozen_time = Time.local(2021, 6, 7, 12, 0, 0)
        Timecop.freeze(frozen_time) do
          allow(ScsbImportJob).to receive(:perform_later)

          described_class.partner_update

          created_dump = described_class.last
          expect(created_dump.dump_type.constant).to eq "PARTNER_RECAP"
          expect(ScsbImportJob).to have_received(:perform_later).with(anything, (frozen_time - 1.day).strftime('%Y-%m-%d %H:%M:%S.%6N %z'))
        end
      end
    end
    context "when there's a previous partner recap dump" do
      it "uses the timestamp from that dump" do
        dump = FactoryBot.create(:empty_partner_recap_dump)
        allow(ScsbImportJob).to receive(:perform_later)

        described_class.partner_update

        created_dump = described_class.last
        expect(created_dump.dump_type.constant).to eq "PARTNER_RECAP"
        expect(ScsbImportJob).to have_received(:perform_later).with(anything, dump.created_at.to_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z'))
      end
    end
  end

  describe '.partner_recap_full' do
    it 'returns dumps with the desired dump_type' do
      dump1 = described_class.create(dump_type: partner_recap_dump_type)
      dump2 = described_class.create(dump_type: partner_recap_full_dump_type)
      dump3 = described_class.create(dump_type: partner_recap_full_dump_type)
      expect(described_class.partner_recap_full.map(&:id)).to contain_exactly(dump2.id, dump3.id)
    end
  end

  describe '#subsequent_partner_incrementals' do
    it "gets all partner_recap dumps with generated_date after mine" do
      dump0 = described_class.create(dump_type: partner_recap_full_dump_type, generated_date: 2.days.ago)
      dump1 = described_class.create(dump_type: partner_recap_dump_type, generated_date: 2.days.ago)
      dump2 = described_class.create(dump_type: partner_recap_dump_type, generated_date: 3.days.ago)
      dump3 = described_class.create(dump_type: partner_recap_dump_type, generated_date: 1.day.ago)
      expect(dump1.subsequent_partner_incrementals).to contain_exactly(dump1, dump3)
    end
  end

  describe '.latest_generated' do
    it 'returns the last-created dump' do
      dump1 = described_class.create(dump_type: partner_recap_dump_type, generated_date: 1.day.ago)
      dump2 = described_class.create(dump_type: partner_recap_dump_type, generated_date: 2.days.ago)
      expect(described_class.latest_generated.id).to eq dump1.id
    end
  end

  describe '#last_incremental_update' do
    it 'returns nil when no dump object is there' do
      described_class.destroy_all
      timestamp = described_class.send(:last_incremental_update)
      expect(timestamp).to be_nil
    end

    it 'sets to create time of previous partner recap dump when there' do
      described_class.create(dump_type: partner_recap_dump_type, created_at: test_create_time)
      timestamp = described_class.send(:last_incremental_update)
      expect(timestamp).to eq(test_create_time)
    end
  end

  describe '#incremental_update_timestamp' do
    it 'returns yesterday when no environment variable or dump object is there' do
      ENV['TIMESTAMP'] = nil
      described_class.destroy_all
      timestamp = described_class.send(:incremental_update_timestamp).to_time.strftime("%Y%m%d")
      expect(timestamp).to eq((DateTime.now - 1).to_time.strftime("%Y%m%d"))
    end

    it 'sets to create time of previous partner recap dump when there' do
      described_class.create(dump_type: partner_recap_dump_type, created_at: test_create_time)
      timestamp = described_class.send(:incremental_update_timestamp)
      expect(timestamp).to eq(test_create_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z'))
    end

    it 'sets to environment variable when there' do
      ENV['TIMESTAMP'] = '2017-07-01'
      timestamp = described_class.send(:incremental_update_timestamp).to_time.strftime("%Y%m%d")
      expect(timestamp).to eq(ENV['TIMESTAMP'].to_time.strftime("%Y%m%d"))
      ENV['TIMESTAMP'] = nil
    end
  end

  describe "##dump_recap_records" do
    it "dumps the records" do
      pending "Replace with Alma"
      # setting created at date to not have nano seconds so that the comapre later will always work correctly
      last_dump = described_class.create(dump_type: princeton_recap_dump_type, event: Event.create(success: true), created_at: Time.zone.now.change(nsec: 0))
      created_at = last_dump.created_at
      expect(created_at).to eq(described_class.last.created_at) # make sure the database time and our stubbed time match otherwise strange errors occur
      # allow(VoyagerHelpers::SyncFu).to receive(:recap_barcodes_since).with(created_at).and_return(["barcode1", "barcode2"])
      expect { described_class.dump_recap_records }.to change { described_class.count }.by(1).and change { DumpFile.count }.by(1)
      expect(described_class.last.update_ids).to contain_exactly("barcode1", "barcode2")
    end
  end
end
