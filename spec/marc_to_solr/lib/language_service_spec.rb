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
  describe "#valid_language_code?" do
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
end
