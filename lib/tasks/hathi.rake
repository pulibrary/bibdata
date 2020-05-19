namespace :hathi do
  
  desc "compact hathi overlap report to only include files that overlap"
  task compact_overlap: :environment do
    if ENV['HATHI_OVERLAP'] && ENV['HATHI_OVERLAP_COMPACTED'] 
      Hathi::CompactOverlap.perform
      output_file = ENV['HATHI_OVERLAP_COMPACTED']
      sorted_file = ENV['HATHI_OVERLAP_COMPACTED_SORTED'] || "#{output_file}.sorted"
      `sort -t$'\t' -k 1n #{output_file} > #{sorted_file}`
    end
  end

  desc 'Compact hathi_full file to include only the identifier and the oclc'
  task compact_full: :environment do
    if ENV['HATHI_FULL'] && ENV['OUTPUT_HATHI']
      Hathi::CompactFull.compact_full
      output_file = "#{ENV['OUTPUT_HATHI']}/compact_hathi_full.tsv"
      `sort -t$'\t' -k 2n #{output_file} > #{ENV['OUTPUT_HATHI']}/compact_hathi_full_sorted.tsv`
    end  
  end

  desc 'Combine Hathi_full and Hathi_overlap_compact files'
  task merge: :environment do
     sorted_file1 = ENV['HATHI_OVERLAP_COMPACTED_SORTED']
     sorted_file2 = "#{ENV['OUTPUT_HATHI']}/compact_hathi_full_sorted.tsv"
     hathi_final = "#{ENV['OUTPUT_HATHI']}"
    `join -t$'\t' -1 1 -2 2 #{sorted_file1 sorted_file2} > #{hathi_final}`
  end  
end
