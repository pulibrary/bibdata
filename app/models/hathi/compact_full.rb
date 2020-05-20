require "csv"

module Hathi
  class CompactFull

    def self.get_full_hathi_file
      hathi_dir = ENV['HATHI_INPUT_DIR']
      get_hathi_file(hathi_dir, "hathi_full*")
    end  

    def self.get_hathi_file(directory, pattern)
      Dir.glob("#{directory}/#{pattern}").sort_by { |filename| filename.to_date.strftime}.last
    end  

    def self.compact_full
      full_hathi_file = get_full_hathi_file
      output_hathi_file = File.join(ENV['HATHI_OUTPUT_DIR'],File.basename(full_hathi_file).gsub('.tsv','_compacted.tsv'))
      CSV.open(output_hathi_file, "wb", col_sep: "\t") do |csv|
        csv << ["identifier","oclc"]
        CSV.foreach(full_hathi_file, col_sep: "\t", liberal_parsing: true) do |row|
          csv << [row[0],row[7]]
        end
      end
    end

  end
end
