namespace :marc_liberation do
  namespace :delete do
    task events: :environment do
      DeleteEventsJob.perform_later(dump_type: 'ALL_RECORDS', older_than: 6.months.ago.to_i)
      DeleteEventsJob.perform_later(dump_type: 'CHANGED_RECORDS', older_than: 2.months.ago.to_i)
    end
  end
end
