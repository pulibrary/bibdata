# frozen_string_literal: true
require "rails_helper"

RSpec.describe Alma::Adapter do
  before do
    Alma.config[:region]='jupiter'
  end

  describe "#base_path" do
    it "returns the Alma base path" do
      expect(described_class.base_path).to eq('jupiter/almaws/v1')
    end
  end

  describe "#region" do
    it "returns the North America Alma region" do
      expect(described_class.region).to eq('jupiter')
    end
  end

  describe "#users_path" do
    it "returns the users path" do
      expect(described_class.users_path).to eq('jupiter/almaws/v1/users')
    end
  end

  describe "#connection" do
    before do
      conn = Faraday::Connection.new 'http://sushi.com'
    end

    it "creates an Alma connection" do
      expect(described_class.connection.class).to be Faraday::Connection
    end

    after do
      Faraday.default_connection = nil
    end
  end
end
