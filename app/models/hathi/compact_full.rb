require "csv"

module Hathi
  # The Full report is everything Hathi has: includes oclc number and hathi id
  # Removes unneeded column values so we only have 'identifier' and 'oclc'
  # This was helpful when we were grepping the csv at index time
  class CompactFull

    def self.get_full_hathi_file
      hathi_dir = ENV['HATHI_INPUT_DIR']
      get_hathi_file(directory: hathi_dir, pattern: "hathi_full*", date_pattern:"hathi_full_%Y%m%d.txt")
    end  

    def self.get_hathi_file(directory:, pattern:, date_pattern:)
      Dir.glob("#{directory}/#{pattern}").sort_by { |filename| Date.strptime(filename,"#{directory}/#{date_pattern}") }.last
    end  

    def self.compact_full
      full_hathi_file = get_full_hathi_file
      output_hathi_file = File.join(ENV['HATHI_OUTPUT_DIR'],File.basename(full_hathi_file).gsub('.txt','_compacted.tsv'))
      CSV.open(output_hathi_file, "wb", col_sep: "\t") do |csv|
        csv << ["identifier","oclc"]
        # setting quote character to cool emoji so we will not loose rows
        CSV.foreach(full_hathi_file, col_sep: "\t", liberal_parsing: true, quote_char: "\u{1f60e}") do |row|
          oclc_ids = (row[7] || "").split(',')
          oclc_ids.each {|oclc_id| csv << [row[0],oclc_id]}
        end
      end
    end

  end
end
