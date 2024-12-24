require 'rails_helper'
RSpec.describe ElectronicAccessLinkFactory do
  it 'can identify that a link is an ark' do
    field = MARC::DataField.new('856', '4', '0',
                                MARC::Subfield.new('u', 'https://arks.princeton.edu/ark:/88435/wh246s44f'))
    expect(described_class.build(bib_id: '123', marc_field: field).ark).to be_truthy
  end
end
