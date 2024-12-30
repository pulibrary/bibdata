require 'rails_helper'

# rubocop:disable Layout/MultilineHashBraceLayout
describe 'From format.rb' do
  let(:marc) { MARC::Record.new }
  let(:marc) { MARC::Record.new }

  { 'Book' => %w[aa ab ac ad am],
    'Journal' => ['as'],
    'Data file' => ['m '],
    'Databases' => ['ai'],
    'Visual material' => ['k ', 'o ', 'r '],
    'Video/Projected medium' => ['g '],
    'Musical score' => ['c ', 'd '],
    'Audio' => ['i ', 'j '],
    'Map' => ['e '],
    'Manuscript' => ['d ', 'f ', 't ', 'p '],
    'Archival item' => ['tm']
  }.each do |k, v|
    it "properly determines format for #{k}" do
      v.each do |c|
        marc.leader[6..7] = c

        if marc.leader[6] == 'a'
          field = MARC::DataField.new('035', '0', '0',
                                      MARC::Subfield.new('a', '(PULFA)'))
          marc.append(field)
        end

        if c == 'tm'
          field = MARC::DataField.new('035', '0', '0',
                                      MARC::Subfield.new('a', '(PULFA)'))
          marc.append(field)
          field = MARC::DataField.new('040', '0', '0',
                                      MARC::Subfield.new('e', 'dacs'))
          marc.append(field)
        end
        fmt = Format.new(marc).bib_format
        expect(Traject::TranslationMap.new('format').translate_array!(fmt)).to include k
      end
    end
  end

  {
    'Book' => ['tm']
  }.each do |k, v|
    it "properly determines format for 'tm' when the record is non-PULFA" do
      v.each do |c|
        marc.leader[6..7] = c
        fmt = Format.new(marc).bib_format
        expect(Traject::TranslationMap.new('format').translate_array!(fmt)).to include k
      end
    end
  end
end
# rubocop:enable Layout/MultilineHashBraceLayout
