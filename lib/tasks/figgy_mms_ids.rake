namespace :figgy_mms_ids do
  desc 'Create a translation map for Traject of mms ids of records in Figgy'
  task build_translation_map: :environment do
    puts("Pulling mms_records report from Figgy and creating Traject translation map - it's a big report, so be patient!")
    destination_file = MmsRecordsReport.new.to_translation_map
    puts("Translation map created at #{destination_file}")
  end
end
