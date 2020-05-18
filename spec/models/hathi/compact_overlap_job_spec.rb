require 'rails_helper'

RSpec.describe Hathi::CompactOverlap do
  it 'distributes an email message to staff when a request fails via the scsb_request queue' do
    overlap_file=File.expand_path("../../../fixtures/overlap.tsv", __FILE__)
    output_file = Tempfile.new('compacted') 
    ENV['HATHI_OVERLAP'] = overlap_file
    ENV['HATHI_OVERLAP_COMPACTED'] = output_file.path
    described_class.perform
    output_file.rewind
    expect(output_file.read).to eq("oclc\tlocal_id\titem_type\taccess\trights\n" \
                                   "32005963\t1000037\tmono\tdeny\tic\n" \
                                   "31088411\t1000038\tmono\tdeny\tic\n" \
                                   "685893\t1000040\tmono\tallow\tpdus\n" \
                                   "242778\t1000046\tmono\tdeny\tic\n")
  end
end
