# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HierarchicalHeading do
  it 'does not include fields that are outside the spec' do
    field = MARC::DataField.new('650', '', '0',
                                MARC::Subfield.new('a', 'International relations.'),
                                MARC::Subfield.new('0', 'http://id.loc.gov/authorities/subjects/sh85067435'))
    spec = Traject::MarcExtractor::Spec.new(tag: '650', indicator1: nil, indicator2: '0', subfields: %w[a y z])
    heading = described_class.new(field:, spec:, split_on_subfield: ['z'])
    expect(heading.to_s).to eq('International relations')
  end
end
