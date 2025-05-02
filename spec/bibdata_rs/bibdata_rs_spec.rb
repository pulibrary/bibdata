require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
# Passing the class name to `describe` loads the class before any new
# rust changes have been compiled, leading to out-of-date test results
describe 'Rust extensions', :rust do
  it 'can be called' do
    expect(BibdataRs.hello).to eq 'toaster'
  end
end
# rubocop:enable RSpec/DescribeClass
