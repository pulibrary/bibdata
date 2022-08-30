require 'rails_helper'

RSpec.describe IndexManager, type: :model, indexing: true do
  let(:solr_url) { ENV["SOLR_URL"] || "http://#{ENV['lando_bibdata_test_solr_conn_host']}:#{ENV['lando_bibdata_test_solr_conn_port']}/solr/bibdata-core-test" }
  let(:solr) { RSolr.connect(url: solr_url) }
  before do
    Sidekiq::BatchSet.new.to_a.each(&:delete)
    solr.delete_by_query("*:*")
    solr.commit
  end

  def run_all_callbacks
    old_batch = nil
    while (batch = Sidekiq::BatchSet.new.to_a.last).bid != old_batch&.bid
      old_batch = batch
      run_callback(batch)
    end
    # Run callback for the parent batch.
    run_callback(Sidekiq::BatchSet.new.to_a.first)
  end

  describe ".rebuild_solr_url" do
    it "appends -rebuild to the URL" do
      expect(described_class.rebuild_solr_url).to eq "#{solr_url}-rebuild"
    end
  end

  describe ".reindex!" do
    it "wipes solr and queues up a full reindex into it" do
      full_event = FactoryBot.create(:full_dump_event)
      incremental_event = FactoryBot.create(:incremental_dump_event)
      existing_index_manager = described_class.for(solr_url)
      existing_index_manager.last_dump_completed = incremental_event.dump
      existing_index_manager.save
      solr.add(id: "should_be_deleted")
      allow(DumpFileIndexJob).to receive(:perform_async).and_call_original
      solr.commit

      Sidekiq::Testing.inline! do
        reindex = described_class.reindex!(solr_url: solr_url)
        expect(reindex).to eq true

        # Checks that a second reindex cannot started while the first one is in progress
        reindex = described_class.reindex!(solr_url: solr_url)
        expect(reindex).to eq false

        run_all_callbacks
      end

      expect(DumpFileIndexJob).to have_received(:perform_async).with(incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(full_event.dump.dump_files.first.id, anything)
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 9
      existing_index_manager.reload
      expect(existing_index_manager.last_dump_completed).to eq incremental_event.dump
      expect(existing_index_manager.dump_in_progress).to be_nil
      expect(existing_index_manager).not_to be_in_progress
    end
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
      expect(index_manager).not_to be_in_progress
    end
    it "doesn't index anything if it's caught up" do
      allow(DumpFileIndexJob).to receive(:perform_async).and_call_original
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
      expect(index_manager).not_to be_in_progress
    end
    it "indexes the previous incremental if the most recent full dump has been done" do
      allow(DumpFileIndexJob).to receive(:perform_async).and_call_original
      # This incremental is before the pre-full-dump incremental, don't run it
      pre_pre_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.days, finish: Time.current - 2.days + 100)
      pre_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.days, finish: Time.current - 2.days + 100)
      full_event = FactoryBot.create(:full_dump_event, start: Time.current - 1.day, finish: Time.current - 1.day + 100)
      # This should get skipped on the third call because events with no files just get skipped
      skipped_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 5.hours, finish: Time.current - 4.hours,
                                                                             dump: FactoryBot.create(:incremental_dump, dump_files: []))
      # This should get run on the third call
      incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 4.hours, finish: Time.current - 3.hours)
      # Incremental that isn't run yet, but would eventually.
      final_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.hours, finish: Time.current - 1.hour)

      index_manager = described_class.for(solr_url)
      Sidekiq::Testing.inline! do
        # Index full dump
        index_manager.index_next_dump!
        run_callback(Sidekiq::BatchSet.new.to_a.last)
        # Index pre-full incremental
        index_manager = described_class.find(index_manager.id)
        index_manager.index_next_dump!
        run_callback(Sidekiq::BatchSet.new.to_a.last)
        # Index post-full incremental
        index_manager = described_class.find(index_manager.id)
        index_manager.index_next_dump!
        run_callback(Sidekiq::BatchSet.new.to_a.last)
      end
      solr.commit

      expect(DumpFileIndexJob).not_to have_received(:perform_async).with(pre_pre_incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(pre_incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(incremental_event.dump.dump_files.first.id, anything)
      # This one doesn't run just because index_next_dump! wasn't called enough
      # times.
      expect(DumpFileIndexJob).not_to have_received(:perform_async).with(final_incremental_event.dump.dump_files.first.id, anything)
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 9
      index_manager.reload
      expect(index_manager.last_dump_completed).to eq incremental_event.dump
      expect(index_manager.dump_in_progress).to be_nil
      expect(index_manager).not_to be_in_progress
    end
  end

  describe "#index_remaining" do
    it "indexes everything that's left to be indexed" do
      allow(DumpFileIndexJob).to receive(:perform_async).and_call_original

      # This incremental is before the full dump, don't run it
      pre_pre_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.days, finish: Time.current - 2.days + 100)
      pre_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.days, finish: Time.current - 2.days + 100)
      full_event = FactoryBot.create(:full_dump_event, start: Time.current - 1.day, finish: Time.current - 1.day + 100)
      incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 4.hours, finish: Time.current - 3.hours)
      final_incremental_event = FactoryBot.create(:incremental_dump_event, start: Time.current - 2.hours, finish: Time.current - 1.hour)

      index_manager = described_class.for(solr_url)
      expect(index_manager).not_to be_in_progress
      Sidekiq::Testing.inline! do
        # Index full dump
        index_manager.index_remaining!
        run_all_callbacks
      end

      expect(DumpFileIndexJob).not_to have_received(:perform_async).with(pre_pre_incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(pre_incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(incremental_event.dump.dump_files.first.id, anything)
      expect(DumpFileIndexJob).to have_received(:perform_async).with(final_incremental_event.dump.dump_files.first.id, anything)
      response = solr.get("select", params: { q: "*:*" })
      expect(response['response']['numFound']).to eq 9
      index_manager.reload
      expect(index_manager.last_dump_completed).to eq final_incremental_event.dump
      expect(index_manager.dump_in_progress).to be_nil
      expect(index_manager).not_to be_in_progress
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
