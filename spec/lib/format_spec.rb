require 'json'
require './lib/format'

describe 'From format.rb' do
  let(:marc) {MARC::Record.new}

  { 'Book' => ['aa', 'ab', 'ac', 'ad', 'ai', 'am'],
    'Journal' => ['as'],
    'Data File' => ['m '],
    'Visual Material' => ['k ', 'o ', 'r '],
    'Video/Projected Medium' => ['g '],
    'Musical Score' => ['c ', 'd '],
    'Audio' => ['i ', 'j '],
    'Map' => ['e '],
    'Manuscript' => ['d ', 'f ', 't ', 'p '],
    'Unknown' => ['  ', 'zz']
  }.each do |k, v|
    it "properly determines format for #{k}" do
      v.each do |c|
        marc.leader[6..7] = c
        fmt = Format.new(marc).bib_format
        expect(Traject::TranslationMap.new("format").translate_array!(fmt)).to include k
      end
    end
  end
end