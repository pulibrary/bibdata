require 'rails_helper'

describe Scsb do
  before do
    class TestLookup
      include Scsb
    end
  end

  after do
    Object.send(:remove_const, :TestLookup)
  end

  describe '#items_by_id' do
    subject(:lookup) { TestLookup.new }

    let(:connection) { instance_double(Faraday::Connection) }
    let(:id) { 'test-id' }
    let(:source) { 'scsb' }

    context 'when connections to the SCSB API endpoint fail' do
      before do
        allow(connection).to receive(:request)
        allow(connection).to receive(:response)
        allow(connection).to receive(:adapter)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed, 'connection failed error')
        allow(Faraday).to receive(:new).and_yield(connection).and_return(connection)
      end

      it 'raises an error' do
        expect { lookup.items_by_id(id, source) }.to raise_error(Faraday::ConnectionFailed)
      end
    end
  end

  describe '#items_by_barcode' do
    subject(:lookup) { TestLookup.new }

    let(:connection) { instance_double(Faraday::Connection) }
    let(:barcodes) { 'test-barcodes' }

    context 'when connections to the SCSB API endpoint fail' do
      before do
        allow(connection).to receive(:request)
        allow(connection).to receive(:response)
        allow(connection).to receive(:adapter)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed, 'connection failed error')
        allow(Faraday).to receive(:new).and_yield(connection).and_return(connection)
      end

      it 'raises an error' do
        expect { lookup.items_by_barcode(barcodes) }.to raise_error(Faraday::ConnectionFailed)
      end
    end
  end
end
