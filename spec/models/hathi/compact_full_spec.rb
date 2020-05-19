require 'rails_helper'

RSpec.describe Hathi::CompactFull do
  describe '#compact_full' do
    
    let(:hathi_directory) { File.expand_path('../../fixtures/', __FILE__)}
    let(:hathi_output) { File.expand_path('../../../tmp', __FILE__)}
    let(:compact_file) {File.join(hathi_output, 'compact_hathi_full.csv')}
    it 'compacts the full hathi file' do
      ENV['OUTPUT_HATHI'] = hathi_output
      ENV['HATHI_FULL'] = hathi_directory
      
      
    end
  end    
end

