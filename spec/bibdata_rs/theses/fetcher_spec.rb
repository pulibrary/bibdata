# frozen_string_literal: true

require 'rails_helper'

module BibdataRs::Theses
  describe 'Fetcher', :rust do
    describe '#_flatten_json' do
      subject { BibdataRs::Theses::Fetcher.new.send(:flatten_json, rest_response).first }
      let(:id) { 'dsp01b2773v788' }
      let(:rest_response) do
        [{
          'id' => 4350,
          'name' => 'Dysfunction: A Play in One Act',
          'handle' => "88435/#{id}",
          'type' => 'item',
          'link' => '/rest/items/4350',
          'expand' => %w[parentCollection parentCollectionList parentCommunityList bitstreams all],
          'lastModified' => '2014-09-09 14:03:06.28',
          'parentCollection' => nil,
          'parentCollectionList' => nil,
          'parentCommunityList' => nil,
          'metadata' => [
            { 'key' => 'dc.contributor', 'value' => 'Wolff, Tamsen', 'language' => nil },
            { 'key' => 'dc.contributor', 'value' => '2nd contributor', 'language' => nil },
            { 'key' => 'dc.contributor.advisor', 'value' => 'Sandberg, Robert', 'language' => nil },
            { 'key' => 'dc.contributor.author', 'value' => 'Clark, Hillary', 'language' => nil },
            { 'key' => 'dc.date.accessioned', 'value' => '2013-07-11T14:31:58Z', 'language' => nil },
            { 'key' => 'dc.date.available', 'value' => '2013-07-11T14:31:58Z', 'language' => nil },
            { 'key' => 'dc.date.created', 'value' => '2013-04-02', 'language' => nil },
            { 'key' => 'dc.date.issued', 'value' => '2013-07-11', 'language' => nil },
            { 'key' => 'dc.identifier.uri', 'value' => "http://arks.princeton.edu/ark:/88435/#{id}",
              'language' => nil },
            { 'key' => 'dc.format.extent', 'value' => '102 pages', 'language' => 'en_US' },
            { 'key' => 'dc.language.iso', 'value' => 'en_US', 'language' => 'en_US' },
            { 'key' => 'dc.title', 'value' => 'Dysfunction: A Play in One Act', 'language' => 'en_US' },
            { 'key' => 'dc.type', 'value' => 'Princeton University Senior Theses', 'language' => nil },
            { 'key' => 'pu.date.classyear', 'value' => '2013', 'language' => 'en_US' },
            { 'key' => 'pu.department', 'value' => 'English', 'language' => 'en_US' },
            { 'key' => 'pu.department', 'value' => 'NA', 'language' => 'en_US' },
            { 'key' => 'pu.certificate', 'value' => 'Creative Writing Program', 'language' => 'en_US' },
            { 'key' => 'pu.certificate', 'value' => 'NA', 'language' => 'en_US' },
            { 'key' => 'pu.pdf.coverpage', 'value' => 'SeniorThesisCoverPage', 'language' => nil },
            { 'key' => 'dc.rights.accessRights', 'value' => 'Walk-in Access...', 'language' => nil }
          ],
          'bitstreams' => nil,
          'archived' => 'true',
          'withdrawn' => 'false'
        }]
      end

      it 'record id extracted from handle field after final slash' do
        expect(subject['id']).to eq(id)
      end

      it 'each key value of the metadata hash is a key in the record hash' do
        rest_response.first['metadata'].each do |m|
          expect(subject.key?(m['key'])).to be true
        end
      end

      it 'supports multiple values if metadata appears more than once' do
        expect(subject['dc.contributor']).to include('Wolff, Tamsen', '2nd contributor')
      end

      it 'maps pu.department to LC authorized name, excludes values not in name list' do
        expect(subject['pu.department']).to include('Princeton University. Department of English')
        expect(subject['pu.department']).not_to include('NA')
        expect(subject['pu.department'].length).to eq 1
      end

      it 'maps pu.department to LC authorized name, excludes values not in name list' do
        expect(subject['pu.certificate']).to include('Princeton University. Creative Writing Program')
        expect(subject['pu.certificate']).not_to include('NA')
        expect(subject['pu.certificate'].length).to eq 1
      end
    end
    describe '#map_program' do
      it 'returns the library of congress program name when it is a match' do
        expect(BibdataRs::Theses::Fetcher.new.send(:map_program, 'African Studies Program')).to eq 'Princeton University. Program in African Studies'
      end
      it 'returns nil when there is no relevant library of congress program name' do
        expect(BibdataRs::Theses::Fetcher.new.send(:map_program, 'Interesting New Program')).to be_nil
      end
    end
  end
end
