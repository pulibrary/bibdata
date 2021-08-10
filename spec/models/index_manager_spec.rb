require 'rails_helper'

RSpec.describe IndexManager, type: :model do
  let(:solr_url) { ENV["SOLR_URL"] || "http://#{ENV['lando_marc_liberation_test_solr_conn_host']}:#{ENV['lando_marc_liberation_test_solr_conn_port']}/solr/marc-liberation-core-test" }
  let(:solr) { RSolr.connect(url: solr_url) }
  before do
    Sidekiq::BatchSet.new.to_a.each(&:delete)
    solr.delete_by_query("*:*")
    solr.commit
  end
  describe "index_next_dump!" do
    it "indexes a full dump if there's been nothing indexed yet" do
      full_event = FactoryBot.create(:full_dump_event)
      incremental_event = FactoryBot.create(:incremental_dump_event)

      index_manager = described_class.for(solr_url)
      Sidekiq::Testing.inline! do
        index_manager.index_next_dump!
      end
      # Have to manually call batch callbacks
      run_callback(Sidekiq::BatchSet.new.to_a.last)
      solr.commit

      response = solr.get("select", params: { q: "*:*" })
      # There's one record in 1.xml, and one record in 2.xml
      expect(response['response']['numFound']).to eq 2
      index_manager.reload
      expect(index_manager.last_dump_completed).to eq full_event.dump
      expect(index_manager.dump_in_progress).to be_nil
    end
    it "doesn't index anything if it's caught up" do
      allow(DumpFileIndexJob).to receive(:perform_async).and_call_original
      # This incremental is before the full dump, don't run it
      full_event = FactoryBot.create(:full_dump_event, start: Time.current - 1.day, finish: Time.current - 1.day + 100)

      index_manager = described_class.for(solr_url)
      Sidekiq::Testing.inline! do
        # Index full dump
        index_manager.index_next_dump!
        run_callback(Sidekiq::BatchSet.new.to_a.last)
        # Index incremental
      end

      index_manager = described_class.find(index_manager.id)
      expect(index_manager.index_next_dump!).to be_nil
      expect(index_manager.reload.dump_in_progress).to be_nil
      expect(DumpFileIndexJob).to have_received(:perform_async).exactly(2).times
    end
    it "indexes the next incremental if the most recent full dump has been done" do
      allow(DumpFileIndexJob).to receive(:perform_async).and_call_original
      # This incremental is before the full dump, don't run it
      pre_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.days, finish: Time.current - 2.days + 100)
      full_event = FactoryBot.create(:full_dump_event, start: Time.current - 1.day, finish: Time.current - 1.day + 100)
      # This should get run on the second call
      incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 4.hours, finish: Time.current - 3.hours)
      # Incremental that isn't run yet, but would eventually.
      final_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.hours, finish: Time.current - 1.hour)

      index_manager = described_class.for(solr_url)
      Sidekiq::Testing.inline! do
        # Index full dump
        index_manager.index_next_dump!
        run_callback(Sidekiq::BatchSet.new.to_a.last)
        # Index incremental
        index_manager = described_class.find(index_manager.id)
        index_manager.index_next_dump!
        run_callback(Sidekiq::BatchSet.new.to_a.last)
      end
      solr.commit

      expect(DumpFileIndexJob).not_to have_received(:perform_async).with(pre_incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).not_to have_received(:perform_async).with(final_incremental_event.dump.dump_files.first.id, anything)
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 9
      index_manager.reload
      expect(index_manager.last_dump_completed).to eq incremental_event.dump
      expect(index_manager.dump_in_progress).to be_nil
    end
  end

  describe "#index_remaining" do
    it "indexes everything that's left to be indexed" do
      allow(DumpFileIndexJob).to receive(:perform_async).and_call_original
      # This incremental is before the full dump, don't run it
      pre_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.days, finish: Time.current - 2.days + 100)
      full_event = FactoryBot.create(:full_dump_event, start: Time.current - 1.day, finish: Time.current - 1.day + 100)
      incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 4.hours, finish: Time.current - 3.hours)
      final_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.hours, finish: Time.current - 1.hour)

      index_manager = described_class.for(solr_url)
      Sidekiq::Testing.inline! do
        # Index full dump
        index_manager.index_remaining!
        old_batch = nil
        while (batch = Sidekiq::BatchSet.new.to_a.last).bid != old_batch&.bid
          old_batch = batch
          run_callback(batch)
        end
        # Run callback for the parent batch.
        run_callback(Sidekiq::BatchSet.new.to_a.first)
      end
      solr.commit

      expect(DumpFileIndexJob).not_to have_received(:perform_async).with(pre_incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(final_incremental_event.dump.dump_files.first.id, anything)
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 9
      index_manager.reload
      expect(index_manager.last_dump_completed).to eq final_incremental_event.dump
      expect(index_manager.dump_in_progress).to be_nil
    end
  end

  def run_callback(batch)
    callback = batch.callbacks["success"][0]
    callback.each do |class_name, args|
      if class_name.include?("#")
        class_name, method_name = class_name.split("#")
        workflow = class_name.constantize.new
        workflow.send(method_name, batch, args)
      else
        class_name.constantize.new.on_success(batch, args)
      end
    end
  end
end
