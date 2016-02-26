require 'rails_helper'

RSpec.describe LanguageService, :type => :service do
  it 'converts language labels to iso codes' do
    expect(described_class.label_to_iso('Chinese')).to eq('zho')
    expect(described_class.label_to_iso('English')).to eq('eng')
  end

  it 'converts loc codes to iso codes' do
    expect(described_class.loc_to_iso('chi')).to eq('zho')
    expect(described_class.loc_to_iso('eng')).to eq('eng')
  end
end
