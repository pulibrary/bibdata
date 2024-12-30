module PartnerFull
  class StartWorkflowJob
    include Sidekiq::Job

    def perform(event_id)
      batch.jobs do
        step1 = Sidekiq::Batch.new
        step1.on(:success, 'PartnerFull::Callbacks#step1_done', 'event_id' => event_id)
        step1.jobs do
          PartnerFull::StartInstitutionJob.perform_async(event_id, 'CUL')
          PartnerFull::StartInstitutionJob.perform_async(event_id, 'HL')
          PartnerFull::StartInstitutionJob.perform_async(event_id, 'NYPL')
        end
      end
    end
  end
end
