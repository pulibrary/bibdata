namespace :marc_liberation do
  namespace :delete do
    task events: :environment do
      DeleteEventsJob.perform_later(dump_type: :full_dump, older_than: 2.months.ago)
      DeleteEventsJob.perform_later(dump_type: :changed_records, older_than: 2.months.ago)
      DeleteEventsJob.perform_later(dump_type: :partner_recap_full, older_than: 2.months.ago)
      DeleteEventsJob.perform_later(dump_type: :partner_recap, older_than: 2.months.ago)
    end
  end
end
