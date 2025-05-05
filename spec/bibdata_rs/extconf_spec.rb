require 'spec_helper'
require_relative '../../lib/bibdata_rs/extconf'

# rubocop:disable RSpec/DescribeClass
describe 'extconf' do
  it 'creates a Makefile' do
    File.delete 'Makefile' if File.exist? 'Makefile'
    BibdataRs::Extconf.makefile
    expect(File).to exist 'Makefile'
    File.delete 'Makefile'
  end
end
# rubocop:enable RSpec/DescribeClass
