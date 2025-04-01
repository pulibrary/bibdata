# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NormalUriFactory do
  let(:nuf) { described_class.new(value: test_uri) }

  context 'a url with queries' do
    let(:test_uri) { 'http://libguides.princeton.edu/content.php?pid=295717&sid=2427989' }

    it 'normalizes uris' do
      expect(nuf.instance_variable_get(:@value)).to eq test_uri
    end
  end

  context 'a url with an anchor link' do
    let(:test_uri) { 'https://catalog.princeton.edu/catalog/4765221#view' }

    it 'does not escape the anchor' do
      expect(nuf.instance_variable_get(:@value)).to eq test_uri
    end
  end
end
