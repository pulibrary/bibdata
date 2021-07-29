require 'rails_helper'

RSpec.describe URI::ARK do
  describe '#princeton_ark?' do
    let(:princeton_ark) { 'http://arks.princeton.edu/ark:/88435/9k41zd556' }
    let(:invalid_princeton_ark) { 'http:http://arks.princeton.edu/ark:/88435/9k41zd556' }
    let(:non_princeton_ark) { 'https://nls.ldls.org.uk/welcome.html?ark:/81055/vdc_100052020059.0x000001' }
    let(:single_slash_ark) { 'http:/arks.princeton.edu/ark:/88435/ff365d62r/pdf' }
    let(:no_http) { 'arks.princeton.edu/ark:/88435/ff365d62r/pdf' }
    it 'Princeton arks return true' do
      expect(described_class.princeton_ark?(url: princeton_ark)).to eq true
    end
    it 'Non-Princeton arks return false' do
      expect(described_class.princeton_ark?(url: non_princeton_ark)).to eq false
    end
    it 'arks that include http twice the url return false ' do
      expect(described_class.princeton_ark?(url: invalid_princeton_ark)).to eq false
    end
    it 'handles single forward slash gracefully' do
      ark = described_class.parse(url: single_slash_ark)
      expect(ark.to_s).to eq "http::80/arks.princeton.edu/ark:/88435/ff365d62r/pdf"
    end
    it 'handles no http' do
      ark = described_class.parse(url: no_http)
      expect(ark.to_s).to eq "arks.princeton.edu/ark:/88435/ff365d62r/pdf"
    end
  end
end
