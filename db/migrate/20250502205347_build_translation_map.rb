class BuildTranslationMap < ActiveRecord::Migration[7.2]
  def change
    Rake::Task['figgy_mms_ids:build_translation_map'].invoke
  rescue MmsRecordsReport::AuthenticationError
    puts("Cannot authenticate to build figgy_mms_ids translation map, skipping.")
  end
end
