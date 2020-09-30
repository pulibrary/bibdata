require 'csv'
namespace :campus_access do
  desc "load a new campus access file for today"
  task load: :environment do
    if ENV['BIBDATA_ACCESS_DIRECTORY']
      today = DateTime.now.strftime('%F')
      file_part = ENV['BIBDATA_ACCESS_FILE_NAME'] || 'Daily file to the Library_fileshare_authorized to be on campus_completed Learn.xlsx'
      trained_file_part = ENV['BIBDATA_TRAINED_FILE_NAME'] || 'Daily file to the Library_fileshare_Learn only.xlsx'
      file_name = File.join(ENV['BIBDATA_ACCESS_DIRECTORY'], file_part)
      trainedfile_name = File.join(ENV['BIBDATA_ACCESS_DIRECTORY'], trained_file_part)
      additional_id_file = Rails.root.join('additional_campus_access.csv')
      additional_ids = CSV.read(additional_id_file, headers: true).map { |row| row[1] }
      if File.exist?(file_name)
        puts "Reading in the daily access file #{file_name}"
        CampusAccess.load_access(file_name, trained_file: trainedfile_name, additional_ids: additional_ids)
        puts "Access allowed for #{CampusAccess.count} patrons today."
      else
        puts "Access file does not exist '#{file_name}'!"
      end
    else
      puts "Environment variable BIBDATA_ACCESS_DIRECTORY must be set!"
    end
  end
end
