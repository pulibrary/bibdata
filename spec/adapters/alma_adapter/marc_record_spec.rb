require 'rails_helper'

RSpec.describe AlmaAdapter::MarcRecord do
  let(:alma_response) { file_fixture("alma/99122426947506421.json").read }
  it "enriches record with catalog date" do
    # Fake a record
    response = JSON.parse(alma_response)["bib"][0]
    bib = Alma::Bib.new(response)
    record = described_class.new(bib, MARC::Record.new)

    # Enrich it
    record.enrich_with_catalog_date("2021-02-25Z")

    # Test it
    field = record.fields.find { |f| f.tag == "876" }
    subfield = field.subfields.find { |s| s.code == "d" }
    expect(subfield.value).to eq("2021-02-25Z")
  end
end
