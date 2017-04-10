namespace :marc_liberation do

  desc 'Runs holding and bib ID dumps and diffs against previous'
  task get_changes: :environment do
    Dump.dump_bib_ids
    Dump.dump_holding_ids
    Dump.diff_since_last
  end

  desc 'Dumps records given BIB_FILE containing ids'
  task bib_dump: :environment do
  	Dump.full_bib_dump
  end

  desc 'Dumps changed ReCAP records by barcode'
  task recap_dump: :environment do
    Dump.dump_recap_records
  end

end
