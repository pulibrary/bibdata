namespace :hathi do
  
  desc "compact hathi overlap report to only include files that overlap"
  task compact_overlap: :environment do |t, args|
    if ENV['HATHI_OVERLAP'] && ENV['HATHI_OVERLAP_COMPACTED']
      Hathi::CompactOverlap.perform
    end
  end

  desc 'Compact hathi_full file to include only the identifier and the oclc'
  task compact_full: :environment do
    if ENV['HATHI_FULL'] && ENV['OUTPUT_HATHI']
      Hathi::CompactFull.compact_full
    end  
  end

end
