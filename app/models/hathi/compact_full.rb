require "csv"

module Hathi
  class CompactFull
    
    @@hathi_dir = ENV['HATHI_FULL']
    @@output_hathi_dir = ENV['OUTPUT_HATHI']
    
    def self.get_full_hathi_file
      Dir.glob("#{@@hathi_dir}/hathi_full*").sort_by { |filename| filename.to_date.strftime}.last
    end  

    def self.compact_full
      CSV.open("#{@@output_hathi_dir}/compact_hathi_full.csv", "wb", col_sep: "\t") do |csv|
        csv << ["url","oclc"]
        CSV.foreach(get_full_hathi_file, col_sep: "\t", headers: true) do |row|
          csv << [row[0],row[7]]
        end
      end
    end
  end
end
