require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
# Passing the class name to `describe` loads the class before any new
# rust changes have been compiled, leading to out-of-date test results
describe 'Rust extensions', :rust do
  it 'adds the BibdataRs::Theses namespace to Ruby' do
    expect { BibdataRs::Theses }.not_to raise_error
  end
end
# rubocop:enable RSpec/DescribeClass
