namespace :marc_liberation do

  desc 'Runs holding and bib ID dumps and diffs against previous'
  task get_changes: :environment do
    Dump.dump_merged_ids
    Dump.diff_since_last
  end

  desc 'Dumps records given BIB_FILE containing ids'
  task bib_dump: :environment do
  	Dump.full_bib_dump
  end

  desc 'Adds updated partner recap records'
  task partner_update: :environment do
  	Dump.partner_update
  end

  desc 'Dumps file of bibs with attached holdings'
  task id_dump: :environment do
    Dump.dump_merged_ids
  end

  desc 'Dumps changed ReCAP records by barcode'
  task recap_dump: :environment do
    Dump.dump_recap_records
  end
end
