class BuildTranslationMap < ActiveRecord::Migration[7.2]
  def change
    Rake::Task['figgy_mms_ids:build_translation_map'].invoke
  end
end
