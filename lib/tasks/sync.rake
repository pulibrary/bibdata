namespace :marc_liberation do
  # desc 'Dumps records given BIB_FILE containing ids'
  # task bib_dump: :environment do
  #   Dump.full_bib_dump
  # end

  desc 'Adds updated partner recap records'
  task partner_update: :environment do
    Dump.partner_update
  end

  desc 'Dumps changed ReCAP records by barcode'
  task recap_dump: :environment do
    Dump.dump_recap_records
  end
end
