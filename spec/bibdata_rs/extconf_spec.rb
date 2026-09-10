require 'spec_helper'
require_relative '../../lib/bibdata_rs/extconf'

# rubocop:disable-next RSpec/DescribeClass
describe 'extconf' do
  it 'creates a Makefile' do
    FileUtils.rm_f 'Makefile'
    BibdataRs::Extconf.makefile
    expect(File).to exist 'Makefile'
    File.delete 'Makefile'
  end

  it 'does not add --timings to the cargo command by default' do
    FileUtils.rm_f 'Makefile'
    BibdataRs::Extconf.makefile
    expect(File.read('Makefile')).not_to include '--timings'
    File.delete 'Makefile'
  end

  it 'adds --timings to the cargo command if PROFILE_COMPILATION=yes' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('PROFILE_COMPILATION').and_return 'yes'
    FileUtils.rm_f 'Makefile'
    BibdataRs::Extconf.makefile
    expect(File.read('Makefile')).to include '--timings'
    File.delete 'Makefile'
  end
end
