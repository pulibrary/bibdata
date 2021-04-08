require "rails_helper"

RSpec.describe AwsSqsPoller do
  include ActiveJob::TestHelper

  let(:poller_mock) do
    Aws::SQS::QueuePoller.new(
      "https://example.com",
      idle_timeout: 1 # stop the polling in test after 1 second so we can run expectations; seems to work as long as we send a final empty message
    )
  end
  let(:message1) do
    { message_id: 'id1', receipt_handle: 'rh1', body: message_body }
  end

  before do
    FactoryBot.create(:full_dump_type)
    FactoryBot.create(:incremental_dump_type)
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

  context "when the process is killed" do
    let(:poller_mock) do
      Aws::SQS::QueuePoller.new(
        "https://example.com"
      )
    end
    let(:job_id) { "1434818870006421" }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_full_dump.json'))).to_json }
    it "doesn't throw an error, logs it, and ends polling" do
      # Add the default signal handler back, RSpec's doesn't kill the process.
      old_signal_handler = Signal.trap 'TERM', 'SYSTEM_DEFAULT'
      # Force a process kill in AlmaDumpTransferJob
      allow(AlmaDumpTransferJob).to receive(:perform_later) do
        Process.kill 'TERM', 0
      end

      described_class.poll

      # Fix the signal handler.
      Signal.trap 'TERM', old_signal_handler
    end
  end

  context "when a full dump job comes through" do
    let(:job_id) { "1434818870006421" }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_full_dump.json'))).to_json }

    it "Creates an event and kicks off a background job" do
      expect { described_class.poll }.to have_enqueued_job(
        AlmaDumpTransferJob
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

  context "when a incremental dump job comes through" do
    let(:job_id) { "6587815790006421" }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_incremental_dump.json'))).to_json }

    it "Creates an event and kicks off a background job" do
      expect { described_class.poll }.to have_enqueued_job(
        AlmaDumpTransferJob
      ).with(
        job_id: job_id,
        dump: instance_of(Dump)
      )

      expect(Dump.all.count).to eq 1
      expect(Dump.first.dump_type.constant).to eq "CHANGED_RECORDS"
      event = Dump.first.event
      expect(event.message_body).to eq message_body
      expect(event.start).to eq "2021-02-08T17:03:52.894Z"
      expect(event.finish).to eq "2021-02-08T20:40:41.941Z"
    end
  end

  context "when a ReCAP dump comes through" do
    let(:job_id) { "6587815790006421" }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_recap_incremental_dump.json'))).to_json }

    it "Creates an event and kicks off a background job" do
      expect { described_class.poll }.to have_enqueued_job(
        AlmaDumpTransferJob
      ).with(
        job_id: job_id,
        dump: instance_of(Dump)
      )

      expect(Dump.all.count).to eq 1
      expect(Dump.first.dump_type.constant).to eq "PRINCETON_RECAP"
      event = Dump.first.event
      expect(event.message_body).to eq message_body
      expect(event.start).to eq "2021-02-08T17:03:52.894Z"
      expect(event.finish).to eq "2021-02-08T20:40:41.941Z"
    end
  end

  context "when some other job comes through" do
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_other_job.json'))).to_json }

    it "Does nothing" do
      expect { described_class.poll }.not_to have_enqueued_job
      expect(Dump.all.count).to eq 0
      expect(Event.all.count).to eq 0
    end
  end
end
