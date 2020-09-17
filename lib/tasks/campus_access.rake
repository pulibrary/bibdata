namespace :campus_access do
  desc "load a new campus access file for today"
  task load: :environment do
    if ENV['BIBDATA_ACCESS_DIRECTORY']
      today = DateTime.now.strftime('%F')
      file_prefix = ENV['BIBDATA_ACCESS_FILE_PREFIX'] || 'Daily file to the Library-'
      file_name = File.join(ENV['BIBDATA_ACCESS_DIRECTORY'],"#{file_prefix}#{today}.xlsx")
      if (File.exist?(file_name))
        puts "Reading in the daily access file #{file_name}"
        CampusAccess.load_access(file_name) 
        puts "Access allowed for #{CampusAccess.count} patrons today." 
      else
        puts "Access file does not exist '#{file_name}'!"
      end
    else
      puts "Environment variable BIBDATA_ACCESS_DIRECTORY must be set!"
    end
  end
end
