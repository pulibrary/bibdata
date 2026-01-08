require 'rails_helper'

RSpec.describe DeleteEventsJob, type: :job do
  around do |example|
    Sidekiq::Testing.inline! do
      example.run
    end
  end

  describe '#perform' do
    let(:copy_path) { File.join('tmp', 'delete_files_job') }

    after { FileUtils.rmtree(copy_path) }

    context 'for full dump events with start date older than 2 months' do
      it 'deletes full dump Events, their Dumps, DumpFiles, and files on disk' do
        old_event = FactoryBot.create(:full_dump_event).tap do |e|
          tmp_dump_files(e)
          e.start = 6.months.ago - 1.day
          e.save
        end
        new_event = FactoryBot.create(:full_dump_event).tap { |e| tmp_dump_files(e) }
        # doesn't delete old incremental events
        incremental_event = FactoryBot.create(:incremental_dump_event).tap do |e|
          tmp_dump_files(e)
          e.start = 6.months.ago - 1.day
          e.save
        end
        described_class.perform_async('full_dump', 2.months.ago.to_s)

        expect(Event.all.to_a.map(&:id)).to contain_exactly(new_event.id, incremental_event.id)
        expect(Dump.all.to_a.map(&:id)).to contain_exactly(new_event.dump.id, incremental_event.dump.id)
        expect(DumpFile.all.to_a.map(&:id)).to match_array(new_event.dump.dump_files.map(&:id) + incremental_event.dump.dump_files.map(&:id))
        expect(Dir.empty?(File.join(copy_path, old_event.id.to_s))).to be true
        expect(Dir.empty?(File.join(copy_path, new_event.id.to_s))).to be false
        expect(Dir.empty?(File.join(copy_path, incremental_event.id.to_s))).to be false
      end
    end

    context 'for incremental dump events with start date older than 2 months' do
      it 'deletes incremental dump Events, their Dumps, DumpFiles, and files on disk' do
        old_event = FactoryBot.create(:incremental_dump_event).tap do |e|
          tmp_dump_files(e)
          e.start = 2.months.ago - 1.day
          e.save
        end
        new_event = FactoryBot.create(:incremental_dump_event).tap { |e| tmp_dump_files(e) }
        # doesn't delete old full events
        full_event = FactoryBot.create(:full_dump_event).tap do |e|
          tmp_dump_files(e)
          e.start = 6.months.ago - 1.day
          e.save
        end

        described_class.perform_async('changed_records', 2.months.ago.to_s)

        expect(Event.all.to_a.map(&:id)).to contain_exactly(new_event.id, full_event.id)
        expect(Dump.all.to_a.map(&:id)).to contain_exactly(new_event.dump.id, full_event.dump.id)
        expect(DumpFile.all.to_a.map(&:id)).to match_array(new_event.dump.dump_files.map(&:id) + full_event.dump.dump_files.map(&:id))
        expect(Dir.empty?(File.join(copy_path, old_event.id.to_s))).to be true
        expect(Dir.empty?(File.join(copy_path, new_event.id.to_s))).to be false
        expect(Dir.empty?(File.join(copy_path, full_event.id.to_s))).to be false
      end
    end

    context 'for partner ReCAP dump events with start date older than 2 months' do
      it 'deletes daily partner ReCAP dump Events, their Dumps, DumpFiles, and files on disk' do
        old_partner_recap_event = FactoryBot.create(:partner_recap_daily_event).tap do |e|
          tmp_dump_files(e)
          e.start = 2.months.ago - 1.day
          e.save
        end
        new_partner_recap_daily_event = FactoryBot.create(:partner_recap_daily_event).tap { |e| tmp_dump_files(e) }
        # Doesn't delete old partner ReCAP full events
        full_partner_recap_event = FactoryBot.create(:partner_recap_full_event).tap do |e|
          tmp_dump_files(e)
          e.start = 6.months.ago - 1.day
          e.save
        end

        described_class.perform_async('partner_recap', 2.months.ago.to_s)

        expect(Event.all.to_a.map(&:id)).to contain_exactly(new_partner_recap_daily_event.id, full_partner_recap_event.id)
        expect(Dump.all.to_a.map(&:id)).to contain_exactly(new_partner_recap_daily_event.dump.id, full_partner_recap_event.dump.id)
        expect(DumpFile.all.to_a.map(&:id)).to match_array(new_partner_recap_daily_event.dump.dump_files.map(&:id) + full_partner_recap_event.dump.dump_files.map(&:id))
        expect(Dir.empty?(File.join(copy_path, old_partner_recap_event.id.to_s))).to be true
        expect(Dir.empty?(File.join(copy_path, new_partner_recap_daily_event.id.to_s))).to be false
        expect(Dir.empty?(File.join(copy_path, full_partner_recap_event.id.to_s))).to be false
      end

      it 'deletes partner ReCAP full dump Events, their Dumps, DumpFiles, and files on disk' do
        old_full_partner_recap_event = FactoryBot.create(:partner_recap_full_event).tap do |e|
          tmp_dump_files(e)
          e.start = 6.months.ago - 1.day
          e.save
        end
        new_full_partner_recap_event = FactoryBot.create(:partner_recap_full_event).tap { |e| tmp_dump_files(e) }
        # doesn't delete old partner ReCAP daily events
        partner_recap_daily_event = FactoryBot.create(:partner_recap_daily_event).tap do |e|
          tmp_dump_files(e)
          e.start = 6.months.ago - 1.day
          e.save
        end

        described_class.perform_async('partner_recap_full', 2.months.ago.to_s)

        expect(Event.all.to_a.map(&:id)).to contain_exactly(new_full_partner_recap_event.id, partner_recap_daily_event.id)
        expect(Dump.all.to_a.map(&:id)).to contain_exactly(new_full_partner_recap_event.dump.id, partner_recap_daily_event.dump.id)
        expect(DumpFile.all.to_a.map(&:id)).to match_array(new_full_partner_recap_event.dump.dump_files.map(&:id) + partner_recap_daily_event.dump.dump_files.map(&:id))
        expect(Dir.empty?(File.join(copy_path, old_full_partner_recap_event.id.to_s))).to be true
        expect(Dir.empty?(File.join(copy_path, new_full_partner_recap_event.id.to_s))).to be false
        expect(Dir.empty?(File.join(copy_path, partner_recap_daily_event.id.to_s))).to be false
      end
    end

    context 'for full dump events that are still associated with an index manager' do
      let!(:index_manager) { FactoryBot.create(:index_manager, dump_in_progress: old_event.dump) }
      let(:old_event) do
        FactoryBot.create(:full_dump_event).tap do |e|
          tmp_dump_files(e)
          e.start = 6.months.ago - 1.day
          e.save
        end
      end

      it 'does not raise an error' do
        expect do
          described_class.perform_async('full_dump', 2.months.ago.to_s)
        end.not_to raise_error
      end

      it 'logs a warning about the failed deletion' do
        allow(Rails.logger).to receive(:warn)
        described_class.perform_async('full_dump', 2.months.ago.to_s)
        expect(Rails.logger).to have_received(:warn).with(/update or delete on table/)
      end
    end
  end
end

# copy the files somewhere and update their paths. We want to make
# sure they get deleted, but not actually delete them from their fixtures
# location
def tmp_dump_files(e)
  e.dump.dump_files.each do |df|
    new_dir = File.join(copy_path, e.id.to_s)
    FileUtils.mkdir_p(new_dir)
    FileUtils.copy(Rails.root.join(df.path), new_dir)
    df.path = File.join(new_dir, File.basename(df.path))
    df.save
  end
end
