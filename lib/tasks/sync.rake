namespace :marc_liberation do

  desc 'Runs holding and bib ID dumps and diffs against previous'
  task get_changes: :environment do
    Dump.dump_bib_ids
    Dump.dump_holding_ids
    Dump.diff_since_last
  end

end
