require 'spec_helper'

RSpec.describe IndigenousLanguages do
  describe '#in_an_indigenous_language?' do
    let(:record) { MARC::Record.new_from_hash('fields' => fields) }

    context 'when 041$a has a relevant language' do
      let(:fields) do
        [
          { '041' => { 'subfields' => [{ 'a' => 'sai' }] } }
        ]
      end

      it 'returns true' do
        expect(LanguageService.new.in_an_indigenous_language?(record)).to be(true)
      end
    end

    context 'when 041$d has a relevant language' do
      let(:fields) do
        [
          { '041' => { 'subfields' => [{ 'a' => 'spa', 'd' => 'nah' }] } }
        ]
      end

      it 'returns true' do
        expect(LanguageService.new.in_an_indigenous_language?(record)).to be(true)
      end
    end

    context 'when 008 has a relevant language' do
      let(:fields) do
        [
          { '008' => '120627s2012    ncuabg  ob    001 0 myn d' }
        ]
      end

      it 'returns true' do
        expect(LanguageService.new.in_an_indigenous_language?(record)).to be(true)
      end
    end

    context 'when 650 has a relevant language and $v Texts' do
      let(:fields) do
        [
          { '650' => { 'subfields' => [{ 'a' => 'Munsee language', 'v' => 'Texts.' }] } }
        ]
      end

      it 'returns true' do
        expect(LanguageService.new.in_an_indigenous_language?(record)).to be(true)
      end
    end

    context 'when 650 has a relevant language but no $v Texts' do
      let(:fields) do
        [
          { '650' => { 'subfields' => [{ 'a' => 'Unami jargon', 'v' => 'Glossaries, vocabularies, etc' }] } }
        ]
      end

      it 'returns true' do
        expect(LanguageService.new.in_an_indigenous_language?(record)).to be(false)
      end
    end
  end

  describe '#subject_headings' do
    it 'is an array of languages taken from the CSV file' do
      expect(LanguageService.new.subject_headings).to include('Puget Sound Salish languages', 'Kalapuya language', 'Spokane language', 'Wyandot language', 'Kootenai language')
    end
  end

  describe '#language_codes' do
    it 'is an array of language codes taken from the CSV file' do
      expect(LanguageService.new.language_codes).to include('alg', 'dak', 'iro', 'nai')
    end
  end
end
