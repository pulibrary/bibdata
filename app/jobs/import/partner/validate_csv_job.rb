module Import
  module Partner
    class ValidateCsvJob
      include Sidekiq::Job

      def perform(dump_id, institution, _file_prefix)
        file = Scsb::PartnerUpdates::Full.download_full_file(institution, 'csv')
        Scsb::PartnerUpdates::Full.validate_csv(dump_id, file, institution)
      end
    end
  end
end
