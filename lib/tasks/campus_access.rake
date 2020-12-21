require 'csv'
namespace :campus_access do
  desc "load a new campus access file for today"
  task load: :environment do
    if ENV['BIBDATA_ACCESS_DIRECTORY']
      file_part = ENV['BIBDATA_ACCESS_FILE_NAME'] || 'Daily file to the Library_fileshare_authorized to be on campus and completed Learn-en.xlsx'
      trained_file_part = ENV['BIBDATA_TRAINED_FILE_NAME'] || 'Daily file to the Library_fileshare_Learn only-en.xlsx'
      file_name = File.join(ENV['BIBDATA_ACCESS_DIRECTORY'], file_part)
      trainedfile_name = File.join(ENV['BIBDATA_ACCESS_DIRECTORY'], trained_file_part)
      additional_access_directory = ENV["CAMPUS_ACCESS_DIRECTORY"] || Rails.root
      additional_id_file = File.join(additional_access_directory, 'additional_campus_access.csv')
      additional_ids = CampusAccessException.new(additional_id_file).current_exceptions
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
