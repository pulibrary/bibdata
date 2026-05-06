# frozen_string_literal: true

require 'rails_helper'
create_global_indexer_service

##
# When our catalog records contain subject headings, that should be classified as
# Indigenous Studies, it adds that term.
RSpec.describe AugmentTheSubject, :indexing do
  let(:ats) { described_class.new }

  context "subfield a's that match by themselves" do
    it 'builds a list of terms from the csv' do
      subfields = described_class.parse_standalone_a
      expect(subfields).to be_a(Hash)
      expect(subfields[:standalone_subfield_a].length).to eq 5599
    end
  end

  context 'required subfields' do
    it 'creates a list of terms with required subfields' do
      subfields = described_class.parse_required_subfields
      parsed_subfields = JSON.parse(subfields)
      expect(parsed_subfields).to be
      expect(parsed_subfields.keys.empty?).to be false
      expect(parsed_subfields.keys.first).to be('Acadians')
      expect(parsed_subfields.values.first[0]).to contain_exactly('History', 'Expulsion, 1755', 'Nova Scotia')
      expect(parsed_subfields['United States'].size).to eq(9)
      expect(parsed_subfields['United States'][3]).to contain_exactly('History', 'Civil War, 1861-1865', 'Participation, Indian')
      expect(parsed_subfields['United States.']).to be

      us_expected = [['Antiquities'],
                     ['Armed Forces', 'Indians'],
                     ['Civilization', 'Indian influences'],
                     ['History', 'Civil War, 1861-1865', 'Participation, Indian'],
                     ['History', 'French and Indian War, 1754-1763'],
                     ['History', "King George's War, 1744-1748"],
                     ['History', "King William's War, 1689-1697"],
                     ['History', "Queen Anne's War, 1702-1713"],
                     ['Politics and government', '1754-1763']]
      expect(parsed_subfields['United States']).to match_array(us_expected)
    end
  end
end
