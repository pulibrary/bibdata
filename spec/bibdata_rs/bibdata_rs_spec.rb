require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
# Passing the class name to `describe` loads the class before any new
# rust changes have been compiled, leading to out-of-date test results
describe 'Rust extensions', :rust do
  it 'can generate JSON' do
    fixture_path = Rails.root.join('spec/fixtures/files/theses/dsp013t945q852.xml').to_s
    parsed = JSON.parse BibdataRs::Theses.json_document(fixture_path)
    expect(parsed['title_citation_display']).to eq 'Bargaining in Basel: The Politics of Global Financial Regulation'
    expect(parsed['title_display']).to eq 'Bargaining in Basel: The Politics of Global Financial Regulation'
    expect(parsed['format']).to eq 'Senior Thesis'
  end
end
# rubocop:enable RSpec/DescribeClass
