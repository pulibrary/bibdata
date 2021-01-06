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

  before do
    Aws.config[:sqs] = {
      stub_responses: {
        receive_message: [
          {
            messages: [
              { message_id: 'id1', receipt_handle: 'rh1', body: '{"job_instance": { "id": job_id, "start_time": "start", "end_time": "end"}}' }
            ]
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

  it "kicks off a background job" do
    expect { described_class.new.poll }.to have_enqueued_job(
      AlmaFullDumpTransferJob
    ).with(
      job_id: job_id,
      dump: instance_of(Dump)
    )

    # expect one Dump to have been created
    # expect the Dump to have the body as its message
    # expect the Dump to have an Event
    # expect event to have the start and end time
  end
end
