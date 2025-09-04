require 'rails_helper'
require 'rake'

# rubocop:disable RSpec/DescribeClass
describe 'Rake tasks' do
  before do
    Rake.application.rake_require('tasks/ephemera')
    Rake::Task.define_task(:environment)
  end

  describe '#delete_all_ephemera_records' do
    let(:solr_double) { instance_spy(RSolr::Client) }
    let(:ids) do
      [
        '123e4567-e89b-12d3-a456-426614174000',
        '12345',
        '678910'
      ]
    end
    let(:uuids) { ids.grep(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/) }
    let(:response_uuids) { { 'response' => { 'docs' => uuids.map { |id| { 'id' => id } } } } }
    let(:response) { { 'response' => { 'docs' => ids.map { |id| { 'id' => id } } } } }

    before do
      allow(RSolr).to receive(:connect).and_return(solr_double)
      match_uuid = 'id:/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/'
      allow(solr_double).to receive(:get).with('select', params: { q: match_uuid, fl: 'id' }).and_return(response_uuids)
      allow(solr_double).to receive(:delete_by_query)
      allow(solr_double).to receive(:commit)
      allow(Rails.application.config).to receive(:solr).and_return({ url: 'http://test-solr' })
      allow(ENV).to receive(:fetch).with('SET_URL', nil).and_return(nil)
    end

    it 'receives a query to delete only UUID records from solr' do
      delete_all_ephemera_records
      # TODO: test the actual rake task and not only the method it's calling
      # Rake::Task['ephemera:delete_all_ephemera_records'].invoke
      # expect { delete_all_ephemera_records }.to output(/Deleting 1 records with UUIDs:\n123e4567-e89b-12d3-a456-426614174000\n/).to_stdout
      expect(solr_double).to have_received(:delete_by_query).with('id:/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/').once
      expect(solr_double).to have_received(:commit)
      expect(solr_double).not_to have_received(:delete_by_query).with(/12345|678910/)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
