namespace :hathi do
  
  desc "compact hathi overlap report to only include files that overlap"
  task compact_overlap: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR']
      puts "compacting the Princeton Hathi Trust overlap file" 
      Hathi::CompactOverlap.perform
      output_file = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: 'overlap*compacted.tsv', date_pattern: 'overlap_%Y%m%d_compacted.tsv')
      puts "Sorting the compacted overlap file #{output_file}" 
      sorted_file = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(output_file).gsub('.tsv','_sorted.tsv'))
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
      output_file = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: 'hathi_full*compacted.tsv', date_pattern:"hathi_full_%Y%m%d_compacted.tsv")
      puts "Sorting the compacted Hathi Trust full index file: #{output_file}" 
      sorted_file = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(output_file).gsub('.tsv','_sorted.tsv'))
      `sort -t$'\t' -k 2n #{output_file} > #{sorted_file}`
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end  
  end

  desc 'Combine Hathi_full and Hathi_overlap_compact files'
  task merge: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR'] 
      sorted_file1 = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'],pattern: 'overlap*sorted.tsv', date_pattern: 'overlap_%Y%m%d_compacted_sorted.tsv')
      sorted_file2 = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'],pattern: 'hathi_full*sorted.tsv', date_pattern:"hathi_full_%Y%m%d_compacted_sorted.tsv")
      hathi_final = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(sorted_file1).gsub('.tsv','_final.tsv'))
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
  
end
