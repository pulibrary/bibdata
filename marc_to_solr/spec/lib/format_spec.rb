require 'json'
require_relative '../../lib/format'

describe 'From format.rb' do
  let(:marc) {MARC::Record.new}

  { 'Book' => ['aa', 'ab', 'ac', 'ad', 'ai', 'am'],
    'Journal' => ['as'],
    'Data file' => ['m '],
    'Visual material' => ['k ', 'o ', 'r '],
    'Video/Projected medium' => ['g '],
    'Musical score' => ['c ', 'd '],
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

  describe '502 note' do
    let(:senior_thesis_502) { {"502"=>{"ind1"=>" ","ind2"=>" ","subfields"=>[{"a"=>"Thesis (Senior)-Princeton University"}]}} }
    let(:senior_thesis_marc) { MARC::Record.new_from_hash({ 'fields' => [senior_thesis_502] }) }
    let(:dissertation_502) { {"502"=>{"ind1"=>" ","ind2"=>" ","subfields"=>[{"a"=>"Not a senior thesis"}]}} }
    let(:dissertation_marc) { MARC::Record.new_from_hash({ 'fields' => [dissertation_502] }) }

    it 'Princeton senior theses are properly classified' do
      senior_thesis_marc.leader = marc.leader
      fmt = Format.new(senior_thesis_marc).bib_format
      expect(Traject::TranslationMap.new("format").translate_array!(fmt)).to include 'Senior thesis'
    end
    it 'Other dissertations are not assigned a separate format' do
      dissertation_marc.leader = marc.leader
      fmt = Format.new(dissertation_marc).bib_format
      expect(Traject::TranslationMap.new("format").translate_array!(fmt)).not_to include 'Dissertation'
    end
  end
end
