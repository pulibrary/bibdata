require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
# Passing the class name to `describe` loads the class before any new
# rust changes have been compiled, leading to out-of-date test results
describe 'Rust extensions', :rust do
  it 'adds the thesis caching function to Ruby' do
    expect(BibdataRs::Theses.methods).to include :all_documents_as_solr
  end

  it 'adds the legacy thesis caching function to Ruby' do
    expect(BibdataRs::Theses.methods).to include :all_legacy_documents_as_solr
  end
end
# rubocop:enable RSpec/DescribeClass
