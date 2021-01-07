require "rails_helper"

RSpec.describe AwsSqsPoller do
  include ActiveJob::TestHelper

  let(:job_id) { "1434818870006421" }
  let(:poller_mock) do
    Aws::SQS::QueuePoller.new(
      "https://example.com",
      idle_timeout: 1 # stop the polling in test after 1 second so we can run expectations; seems to work as long as we send a final empty message
    )
  end
  let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_full_dump.json'))).to_json }
  let(:message1) do
    { message_id: 'id1', receipt_handle: 'rh1', body: message_body }
  end

  before do
    FactoryBot.create(:full_dump_type)
    Aws.config[:sqs] = {
      stub_responses: {
        receive_message: [
          {
            messages: [message1]
          },
          { messages: [] }
        ]
      }
    }
    allow(Aws::SQS::QueuePoller).to receive(:new).and_return(poller_mock)
  end

  after do
    # ensure no state leak between tests
    Aws.config.clear
  end

  it "Creates an event and kicks off a background job" do
    expect { described_class.new.poll }.to have_enqueued_job(
      AlmaFullDumpTransferJob
    ).with(
      job_id: job_id,
      dump: instance_of(Dump)
    )

    expect(Dump.all.count).to eq 1
    expect(Dump.first.dump_type.constant).to eq "ALL_RECORDS"
    event = Dump.first.event
    expect(event.message_body).to eq message_body
    expect(event.start).to eq "2020-12-15T19:56:37.694Z"
    expect(event.finish).to eq "2020-12-15T19:56:55.145Z"
  end
end
