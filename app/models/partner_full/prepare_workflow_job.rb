module PartnerFull
  class PrepareWorkflowJob
    include Sidekiq::Job

    def perform
      event = prepare_event
      prepare_directory
      overall = Sidekiq::Batch.new
      overall.description = "Overarching batch for for event #{event.id}"
      overall.on(:success, 'PartnerFull::Callbacks#all_steps_done', 'event_id' => event.id)
      overall.jobs do
        PartnerFull::StartWorkflowJob.perform_async(event.id)
      end
    end

    def prepare_event
      event = Event.new
      event.start = Time.now.utc
      event.save!
      event.dump = Dump.create!(dump_type: :partner_recap_full, event_id: event.id)
      event.save!
      event
    end

    def prepare_directory
      update_directory = ENV.fetch('SCSB_PARTNER_UPDATE_DIRECTORY', '/tmp/updates')
      FileUtils.mkdir_p(update_directory)
    end
  end
end
