# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlmaAdapter::Connector do
  before do
    updated_config = Rails.configuration.alma.merge(region: 'jupiter')
    allow(Rails.configuration).to receive(:alma).and_return(updated_config)
  end

  describe '#base_path' do
    it 'returns the Alma base path' do
      expect(described_class.base_path).to eq('jupiter/almaws/v1')
    end
  end

  describe '#region' do
    it 'returns the North America Alma region' do
      expect(described_class.region).to eq('jupiter')
    end
  end

  describe '#users_path' do
    it 'returns the users path' do
      expect(described_class.users_path).to eq('jupiter/almaws/v1/users')
    end
  end

  describe '#connection' do
    it 'creates an Alma connection' do
      expect(described_class.connection.class).to be Faraday::Connection
    end
  end
end
