namespace :hathi do
  
  desc "compact hathi overlap report to only include files that overlap"
  task compact_overlap: :environment do |t, args|
    if ENV['HATHI_OVERLAP'] && ENV['HATHI_OVERLAP_COMPACTED']
      Hathi::CompactOverlap.perform
    end
  end

end
