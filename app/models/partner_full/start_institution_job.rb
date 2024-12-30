module PartnerFull
  class StartInstitutionJob
    include Sidekiq::Job

    def perform(_event_id, _institution)
      true
    end
  end
end
