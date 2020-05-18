require 'csv'
module Hathi
  class CompactOverlap
    def self.perform
      overlap_file = ENV['HATHI_OVERLAP']
      compacted_overlap_file = ENV['HATHI_OVERLAP_COMPACTED']
      ::CSV.open(compacted_overlap_file, "wb", col_sep: "\t") do |csv|
        first = true
        ::CSV.foreach(overlap_file, col_sep: "\t", headers: true) do |row|
          csv << row.headers() if first
          csv << row if row["access"] == "allow" || row["access"] == "deny"
          first = false
        end  
      end
    end
  end  
end
