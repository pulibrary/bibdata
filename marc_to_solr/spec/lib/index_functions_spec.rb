require_relative '../../lib/index_functions'

RSpec.describe IndexFunctions do
  describe '#delete_ids' do
    let(:dump) do
      { 'ids' =>
        { 'delete_ids' => ['134', '234'] } }
    end
    it 'reuturns an array of bib ids for deletion' do
      expect(described_class.delete_ids(dump)).to eq ['134', '234']
    end
  end
  describe '#rsolr_connection' do
    let(:solr) { described_class.rsolr_connection('http://example.com') }
    it 'responds to .commit' do
      expect(solr).to respond_to(:commit)
    end
    it 'responds to .delete_by_id' do
      expect(solr).to respond_to(:delete_by_id).with(1).argument
    end
  end
end
