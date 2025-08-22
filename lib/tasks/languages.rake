require_relative '../bibdata_rs'

namespace :languages do
  namespace :iso639_2b do
    desc 'update the list of ISO 639-2b codes for use in rust code'
    task refresh_list: :environment do
      file_handle = File.new Rails.root.join('lib/bibdata_rs/src/languages/iso_639_2b.rs'), 'w'
      BibdataRs::UpdateIso6392bLanguageData.new(file_handle).call
    end
  end
  namespace :iso639_3 do
    desc 'update the list of ISO 639-3 codes for use in rust code'
    task refresh_list: :environment do
      file_handle = File.new Rails.root.join('lib/bibdata_rs/src/languages/iso_639_3.rs'), 'w'
      BibdataRs::UpdateIso6393LanguageData.new(file_handle).call
    end
  end
  namespace :iso639_5 do
    desc 'update the list of ISO 639-5 codes for use in rust code'
    task refresh_list: :environment do
      file_handle = File.new Rails.root.join('lib/bibdata_rs/src/languages/iso_639_5.rs'), 'w'
      BibdataRs::UpdateIso6395LanguageData.new(file_handle).call
    end
  end
end
