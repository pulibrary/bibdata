# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LanguageExtractor do
  let(:fields) do
    [
      { '008' => '120627s2012    ncuabg  ob    001 0 gre d' }
    ]
  end
  let(:extractor) { described_class.new(LanguageService.new, MARC::Record.new_from_hash('fields' => fields)) }
  it 'finds a language from the 008' do
    expect(extractor.specific_names).to eq(['Modern Greek (1453-)'])
  end
  context 'when the 008 is a collective code' do
    let(:fields) do
      [
        { '008' => '120627s2012    ncuabg  ob    001 0 myn d' }
      ]
    end
    it 'provides the collective name' do
      expect(extractor.specific_names).to eq(['Mayan languages'])
    end
  end
  context 'when language info in the 041' do
    let(:fields) do
      [
        { '008' => '120627s2012    ncuabg  ob    001 0 myn d' },
        { '041' => { 'subfields' => [{ 'a' => 'nah' }] } }
      ]
    end
    it 'includes the language from the 041' do
      expect(extractor.specific_names).to include('Nahuatl languages')
    end
    it 'includes the language from the 008' do
      expect(extractor.specific_names).to include('Mayan languages')
    end
  end
  context 'when ISO 639-3 language info in the 041' do
    let(:fields) do
      [
        { '008' => '120627s2012    ncuabg  ob    001 0 myn d' },
        { '041' => { 'subfields' => [{ 'a' => 'nah' }] } },
        { '041' => { 'subfields' => [{ 'a' => 'nuz' }, { '2' => 'iso639-3' }] } }
      ]
    end
    it 'prefers ISO 639-3 language codes to MARC language codes' do
      expect(extractor.specific_names).to include('Tlamacazapa Nahuatl')
      expect(extractor.specific_names).not_to include('Nahuatl languages')
    end
    it 'includes the language from the 008' do
      expect(extractor.specific_names).to include('Mayan languages')
    end
    context 'when 008 is a macrolanguage of the ISO 639-3 specific language' do
      let(:fields) do
        [
          { '008' => '120627s2012    ncuabg  ob    001 0 chi d' },
          { '041' => { 'subfields' => [{ 'a' => 'wuu' }, { '2' => 'iso639-3' }] } }
        ]
      end
      it 'includes only the specific language' do
        expect(extractor.specific_names).to include('Wu Chinese')
        expect(extractor.specific_names).not_to include('Chinese')
      end
    end
    context '041$h' do
      let(:fields) do
        [
          { '008' => '120627s2012    ncuabg  ob    001 0 chi d' },
          { '041' => { 'subfields' => [{ 'a' => 'chi' }, { 'h' => 'eng' }] } }
        ]
      end
      it 'does not include the translation from 041$h' do
        expect(extractor.specific_names).to include('Chinese')
        expect(extractor.specific_names).not_to include('English')
      end
    end
    context '041$d' do
      let(:fields) do
        [
          { '008' => '120627s2012    ncuabg  ob    001 0 spa d' },
          { '041' => { 'subfields' => [{ 'a' => 'spa' }, { 'd' => 'por' }] } }
        ]
      end
      it 'includes the spoken language from 041$d' do
        expect(extractor.specific_names).to contain_exactly('Spanish', 'Portuguese')
      end
    end
  end
  describe('#possible_language_subject_headings') do
    let(:fields) do
      [
        { '650' => { 'subfields' => [{ 'a' => 'Kootenai language' }, { 'v' => 'Texts' }] } }
      ]
    end
    it 'includes the subject heading from the 650$a if 650$v is Texts' do
      expect(extractor.possible_language_subject_headings).to contain_exactly('Kootenai language')
    end
  end
end
