require 'faraday'
require 'rsolr'

default_bibdata_url = 'https://bibdata-alma-staging.princeton.edu'
bibdata_url = ENV['BIBDATA_URL'] || default_bibdata_url

conn = Faraday.new(url: bibdata_url) do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

namespace :hathi do
  desc "load institution-specific hathi overlap file into HathiAccess objects"
  task load_access: :environment do
    input_location = ENV['HATHI_INPUT']
    origin = ENV['HATHI_ORIGIN']
    abort "usage: HATHI_INPUT=/path/to/file.tsv HATHI_ORIGIN=CUL rake hathi:load_access" unless input_location && origin
    before_count = HathiAccess.all.count
    Hathi::LoadAccessFile.new(input_location: input_location, origin: origin).load
    after_count = HathiAccess.all.count
    puts "#{after_count - before_count} records created"
  end

  desc "compact hathi overlap report to only include files that overlap"
  task compact_overlap: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR']
      school = ENV['HATHI_SCHOOL'] || 'princeton'
      puts "compacting the #{school} Hathi Trust overlap file"
      output_file = Hathi::CompactOverlap.perform(school: school)
      puts "Sorting the compacted overlap file #{output_file}"
      sorted_file = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(output_file).gsub('.tsv', '_sorted.tsv'))
      `sort -t$'\t' -k 1n #{output_file} > #{sorted_file}`
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end
  end

  desc 'Compact hathi_full file to only include the identifier and the oclc'
  task compact_full: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR']
      puts "compacting the Hathi Trust full index file"
      Hathi::CompactFull.compact_full
      output_file = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: 'hathi_full*compacted.tsv', date_pattern: "hathi_full_%Y%m%d_compacted.tsv")
      puts "Sorting the compacted Hathi Trust full index file: #{output_file}"
      sorted_file = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(output_file).gsub('.tsv', '_sorted.tsv'))
      `sort -t$'\t' -k 2n #{output_file} > #{sorted_file}`
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end
  end

  desc 'Combine Hathi_full and Hathi_overlap_compact files'
  task merge: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR']
      school = ENV['HATHI_SCHOOL'] || 'princeton'
      sorted_file1 = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: "overlap*_#{school}_sorted.tsv", date_pattern: "overlap_%Y%m%d_compacted_#{school}_sorted.tsv")
      sorted_file2 = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: 'hathi_full*sorted.tsv', date_pattern: "hathi_full_%Y%m%d_compacted_sorted.tsv")
      hathi_final = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(sorted_file1).gsub('.tsv', '_final.tsv'))
      puts "Merging #{sorted_file1} & #{sorted_file2} on oclc number"
      `join -t$'\t' -1 1 -2 2 #{sorted_file1} #{sorted_file2} > #{hathi_final}`
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end
  end

  desc 'Compact the Full Hathi Data the Overlap file and combine the files'
  task compact_and_merge: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR']
      Rake::Task["hathi:compact_overlap"].invoke
      Rake::Task["hathi:compact_full"].invoke
      Rake::Task["hathi:merge"].invoke
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end
  end

  desc 'Index Hathi records using the Hathi final file. (SET_URL: set the solr url)'
  task index_csv: :environment do
    ENV['RUN_HATHI_COMPARE'] = 'true'
    solr_url = ENV['SET_URL']
    solr = IndexFunctions.rsolr_connection(solr_url)
    url_arg = ENV['SET_URL'] ? "-u #{ENV['SET_URL']}" : ''
    if ENV['HATHI_OUTPUT_DIR']
      hathi_file = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: 'overlap*compacted_sorted_final.tsv', date_pattern: 'overlap_%Y%m%d_compacted_sorted_final.tsv')
      if hathi_file.present?
        CSV.foreach(hathi_file, col_sep: "\t", headers: true) do |row|
          if row[1].present?
            ENV['BIB'] = row[1]
            # `SET_ULR=#{solr_url} BIB=#{ENV['BIB']} bundle exec bin/rake #{Rake::Task["liberate:bib"].execute}`
            if ENV['BIB']
              resp = conn.get "/bibliographic/#{ENV['BIB']}"
              File.binwrite('./tmp/tmp.xml', resp.body)
              sh "traject -c marc_to_solr/lib/traject_config.rb ./tmp/tmp.xml #{url_arg}"
            else
              puts 'Please provide a BIB argument (BIB=####)'
            end
          else
            Rails.logger.error("#{row} is missing oclc")
          end
        end
        solr.commit
      else
        puts "hathi_file is missing from #{ENV['HATHI_OUTPUT_DIR']}"
      end
    else
      puts "Environment variable HATHI_OUTPUT_DIR must be set!"
    end
  end
end
