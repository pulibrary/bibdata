namespace :marc_liberation do
  desc 'Adds updated partner recap records'
  task partner_update: :environment do
    Dump.partner_update
  end

  desc 'Dumps changed ReCAP records by barcode'
  task recap_dump: :environment do
    Dump.dump_recap_records
  end
end
