require 'csv'
module Hathi
  # Overlap file is everything Hathi has that given institution also has)
  # Contains oclc number, institution ID, and status
  # Status: 'allow' means open access, 'deny' means only available for access
  #   according to the Emergency Temporary Access Service (ETAS)
  # Gets rid of rows for items that are neither ALLOW nor DENY
  # Also removes all column values except oclc number, bib, and status
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
