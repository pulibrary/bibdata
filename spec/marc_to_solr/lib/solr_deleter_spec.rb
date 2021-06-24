# encoding: UTF-8
require 'rails_helper'

describe SolrDeleter do
  subject(:solr_deleter) { described_class.new(solr_url, logger) }
  let(:solr_url) { "http://localhost:8983/solr/bibdata" }
  let(:logger) { instance_double(ActiveSupport::Logger) }

  before do
    WebMock.disable_net_connect!
  end

  after do
    WebMock.disable_net_connect!(Rails.application.config.webmock_disable_opts)
  end

  # Note there is another deletion test in spec/alma/services/indexer_spec
  describe '#delete' do
    let(:ids) do
      [
        "10744406",
        "10744403"
      ]
    end
    let(:batch_size) { ids.length }
    let(:url) do
      "http://localhost:8983/solr/bibdata/update?commit=true&wt=json"
    end

    context 'when solr returns 200' do
      before do
        allow(logger).to receive(:info)
        stub_request(:post, url).to_return(status: 200)
      end

      it 'requests to delete the Documents from Solr' do
        solr_deleter.delete(ids, batch_size)
        expect(logger).to have_received(:info).with("Deleting <delete><id>10744406</id><id>10744403</id></delete>")
        expect(
          a_request(:post, url).with(
            body: "<delete><id>10744406</id><id>10744403</id></delete>"
          )
        ).to have_been_made.once
      end
    end

    context 'when the HTTP request to Solr times out' do
      let(:logger) do
        instance_double(ActiveSupport::Logger)
      end

      before do
        allow(Faraday).to receive(:post).and_raise(Faraday::TimeoutError)
        allow(logger).to receive(:info)
        allow(logger).to receive(:warn)

        solr_deleter.delete(ids, batch_size)
      end

      it 'logs a warning' do
        expect(logger).to have_received(:warn).exactly(2).times.with(/^Delete timed out /)
      end
    end

    context 'when the request to Solr fails once' do
      before do
        allow(logger).to receive(:info)
        stub_request(:post, url).to_return(
          { status: 500 },
          { status: 200 }
        )
      end

      it 'retransmits the request' do
        solr_deleter.delete(ids, batch_size)
        expect(logger).to have_received(:info).with("Deleting <delete><id>10744406</id><id>10744403</id></delete>").twice
        expect(
          a_request(:post, url).with(
            body: "<delete><id>10744406</id><id>10744403</id></delete>"
          )
        ).to have_been_made.twice
      end
    end

    context 'when the request to Solr fails more than once' do
      before do
        allow(logger).to receive(:info)
        allow(Honeybadger).to receive(:notify)
        stub_request(:post, url).to_return(
          { status: 500 },
          { status: 500 },
          { status: 200 }
        )
      end

      it 'retransmits the request only once' do
        solr_deleter.delete(ids, batch_size)
        expect(logger).to have_received(:info).with("Deleting <delete><id>10744406</id><id>10744403</id></delete>").twice
        expect(
          a_request(:post, url).with(
            body: "<delete><id>10744406</id><id>10744403</id></delete>"
          )
        ).to have_been_made.twice
        expect(Honeybadger).to have_received :notify
      end
    end
  end
end
