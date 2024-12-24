# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LanguageService, type: :service do
  describe '#loc_to_iana' do
    it 'shortens to the two-character form' do
      expect(described_class.new.loc_to_iana('eng')).to eq('en')
    end

    it 'handles cases where ISO 639-2 preferred codes are different from the MARC standard' do
      expect(described_class.new.loc_to_iana('chi')).to eq('zh')
    end

    it 'handles non-languages from the MARC standard' do
      expect(described_class.new.loc_to_iana('zxx')).to eq('en')
    end
  end

  describe '#valid_language_code?' do
    it 'returns true for a valid ISO language code' do
      expect(described_class.new.valid_language_code?('grc')).to be(true)
    end

    it 'returns true for a valid ISO 639-5 collective code' do
      expect(described_class.new.valid_language_code?('nah')).to be(true)
    end

    it 'returns false for an invalid ISO language code' do
      expect(described_class.new.valid_language_code?('123')).to be(false)
    end
  end

  describe('#specific_names') do
    let(:fields) do
      [
        { '008' => '120627s2012    ncuabg  ob    001 0 gre d' }
      ]
    end
    let(:specific_names) { described_class.new.specific_names(MARC::Record.new_from_hash('fields' => fields)) }

    it 'finds a language from the 008' do
      expect(specific_names).to eq(['Modern Greek (1453-)'])
    end

    context 'when the 008 is a collective code' do
      let(:fields) do
        [
          { '008' => '120627s2012    ncuabg  ob    001 0 myn d' }
        ]
      end

      it 'provides the collective name' do
        expect(specific_names).to eq(['Mayan languages'])
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
        expect(specific_names).to include('Nahuatl languages')
      end

      it 'includes the language from the 008' do
        expect(specific_names).to include('Mayan languages')
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
        expect(specific_names).to include('Tlamacazapa Nahuatl')
        expect(specific_names).not_to include('Nahuatl languages')
      end

      it 'includes the language from the 008' do
        expect(specific_names).to include('Mayan languages')
      end

      context 'when 008 is a macrolanguage of the ISO 639-3 specific language' do
        let(:fields) do
          [
            { '008' => '120627s2012    ncuabg  ob    001 0 chi d' },
            { '041' => { 'subfields' => [{ 'a' => 'wuu' }, { '2' => 'iso639-3' }] } }
          ]
        end

        it 'includes only the specific language' do
          expect(specific_names).to include('Wu Chinese')
          expect(specific_names).not_to include('Chinese')
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
          expect(specific_names).to include('Chinese')
          expect(specific_names).not_to include('English')
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
          expect(specific_names).to contain_exactly('Spanish', 'Portuguese')
        end
      end
    end
  end
end
