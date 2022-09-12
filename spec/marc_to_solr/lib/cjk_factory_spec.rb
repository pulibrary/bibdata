# frozen_string_literal: true
require 'rails_helper'

describe 'CJK Factory' do
  let(:traditional_chinese_name) { '沈從文' }
  let(:simplified_chinese_name) { '沈从文' }
  let(:katakana_word) { 'アメリカ' }
  let(:hiragana_word) { 'あめりか' }
  it 'can accurately identify Chinese characters' do
    expect(CJKFactory.contains_chinese?(traditional_chinese_name)).to be_truthy
    expect(CJKFactory.contains_chinese?(katakana_word)).to be_falsey
  end

  it 'can accurately identify Katakana' do
    expect(CJKFactory.contains_katakana?(katakana_word)).to be_truthy
    expect(CJKFactory.contains_katakana?(traditional_chinese_name)).to be_falsey
  end

  it 'can transliterate Traditional Chinese characters to Simplified' do
    expect(CJKFactory.traditional_to_simplified(traditional_chinese_name)).to eq(simplified_chinese_name)
  end

  it 'can transliterate Katakana to Hiragana' do
    expect(CJKFactory.katakana_to_hiragana(katakana_word)).to eq(hiragana_word)
  end
end
