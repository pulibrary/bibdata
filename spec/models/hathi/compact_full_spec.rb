require 'rails_helper'

RSpec.describe Hathi::CompactFull do
  describe '#compact_full' do
    
    let(:hathi_directory) { File.expand_path('../../../fixtures/', __FILE__)}
    let(:hathi_output) { File.expand_path('../../../../tmp', __FILE__)}
    let(:compact_file) {File.join(hathi_output, 'compact_hathi_full.csv')}
    
    it 'compacts the full hathi file' do
      ENV['OUTPUT_HATHI'] = hathi_output
      ENV['HATHI_FULL'] = hathi_directory
      output_file = File.open(compact_file)
      described_class.compact_full
      expect(output_file.read).to eq("identifier\toclc\n"\
                                     "mdp.39015066356547\t2779601\n"\
                                     "mdp.39015066356406\t2779601\n"\
                                     "mdp.39015066356695\t2779601\n"\
                                     "mdp.39015066356554\t2779601\n"\
                                     "uc1.$b759626\t2779601\n"\
                                     "uc1.$b759627\t2779601\n"\
                                     "uc1.$b759628\t2779601\n"\
                                     "mdp.39015033913115\t23536349\n"\
                                     "mdp.39015061455294\t60561774\n") 
    end
  end
end
