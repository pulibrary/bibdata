namespace :marc_liberation do
  namespace :delete do
    task events: :environment do
      older_than = 2.months.ago.to_s
      DeleteEventsJob.perform_async('full_dump', older_than)
      DeleteEventsJob.perform_async('changed_records', older_than)
      DeleteEventsJob.perform_async('partner_recap_full', older_than)
      DeleteEventsJob.perform_async('partner_recap', older_than)
    end
  end
end
