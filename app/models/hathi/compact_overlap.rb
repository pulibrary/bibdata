require 'csv'
module Hathi
  class CompactOverlap
    def self.perform(school: 'princeton')
      overlap_file = CompactFull.get_hathi_file(directory: ENV['HATHI_INPUT_DIR'], pattern: "overlap*#{school}.tsv", date_pattern: "overlap_%Y%m%d_#{school}.tsv")
      compacted_overlap_file = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(overlap_file).gsub(school,"compacted_#{school}"))
      ::CSV.open(compacted_overlap_file, "wb", col_sep: "\t") do |csv|
        first = true
        ::CSV.foreach(overlap_file, col_sep: "\t", headers: true) do |row|
          csv << row.headers() if first
          csv << row if row["access"] == "allow" || row["access"] == "deny"
          first = false
        end
      end
      compacted_overlap_file
    end
  end  
end
