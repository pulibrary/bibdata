require 'spec_helper'

RSpec.describe URI::ARK do
  describe '#princeton_ark?' do
    let(:princeton_ark) { 'http://arks.princeton.edu/ark:/88435/9k41zd556' }
    let(:invalid_princeton_ark) { 'http:http://arks.princeton.edu/ark:/88435/9k41zd556' }
    let(:non_princeton_ark) { 'https://nls.ldls.org.uk/welcome.html?ark:/81055/vdc_100052020059.0x000001' }
    let(:single_slash_ark) { 'http:/arks.princeton.edu/ark:/88435/ff365d62r/pdf' }

    it 'Princeton arks return true' do
      expect(described_class.princeton_ark?(url: princeton_ark)).to be true
    end

    it 'Non-Princeton arks return false' do
      expect(described_class.princeton_ark?(url: non_princeton_ark)).to be false
    end

    it 'arks that include http twice the url return false' do
      expect(described_class.princeton_ark?(url: invalid_princeton_ark)).to be false
    end

    it 'Invalid Princeton arks return false' do
      expect(described_class.princeton_ark?(url: single_slash_ark)).to be false
    end
  end
end
