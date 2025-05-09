require 'rails_helper'

RSpec.describe AwsSqsPoller do
  let(:poller_mock) do
    Aws::SQS::QueuePoller.new(
      'https://example.com',
      idle_timeout: 1 # stop the polling in test after 1 second so we can run expectations; seems to work as long as we send a final empty message
    )
  end
  let(:message1) do
    { message_id: 'id1', receipt_handle: 'rh1', body: message_body }
  end

  before do
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

  context 'when the process is killed' do
    let(:poller_mock) do
      Aws::SQS::QueuePoller.new(
        'https://example.com'
      )
    end
    let(:job_id) { '1434818870006421' }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_full_dump.json'))).to_json }

    it "doesn't throw an error, logs it, and ends polling" do
      # Add the default signal handler back, RSpec's doesn't kill the process.
      old_signal_handler = Signal.trap 'TERM', 'SYSTEM_DEFAULT'
      # Force a process kill in Import::Alma
      allow(Import::Alma).to receive(:perform_async) do
        Process.kill 'TERM', 0
      end

      described_class.poll
      # If it makes it this far polling didn't go infinitely and RSpec didn't
      # get killed.

      # Fix the signal handler.
      Signal.trap 'TERM', old_signal_handler
    end
  end

  context 'when a full dump job comes through' do
    let(:job_id) { '1434818870006421' }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_full_dump.json'))).to_json }

    it 'Creates an event and kicks off a background job' do
      allow(Import::Alma).to receive(:perform_async)
      described_class.poll
      expect(Import::Alma).to have_received(:perform_async).with(instance_of(Integer), job_id)
      expect(Dump.all.count).to eq 1
      expect(Dump.first.dump_type).to eq('full_dump')
      event = Dump.first.event
      expect(event.message_body).to eq message_body
      expect(event.start).to eq '2020-12-15T19:56:37.694Z'
      expect(event.finish).to eq '2020-12-15T19:56:55.145Z'
      expect(Dump.first.generated_date).to eq event.start
    end
  end

  context 'when a incremental dump job comes through' do
    let(:job_id) { '6587815790006421' }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_incremental_dump.json'))).to_json }

    context 'with a duplicate event' do
      before do
        Event.create!(message_body:)
      end

      it "doesn't raise an error or kicks off a background job" do
        allow(Rails.logger).to receive(:error)
        allow(Import::Alma).to receive(:perform_async)
        described_class.poll
        expect(Import::Alma).not_to have_received(:perform_async)
        expect(Rails.logger).to have_received(:error).with('Rescue from AlmaDuplicateEventError with alma_process_id: 6587815790006421')
      end
    end

    it 'Creates an event and kicks off a background job' do
      allow(Import::Alma).to receive(:perform_async)
      described_class.poll
      expect(Import::Alma).to have_received(:perform_async).with(instance_of(Integer), job_id)
      expect(Dump.all.count).to eq 1
      expect(Dump.first.dump_type).to eq 'changed_records'
      event = Dump.first.event
      expect(event.message_body).to eq message_body
      expect(event.start).to eq '2021-02-08T17:03:52.894Z'
      expect(event.finish).to eq '2021-02-08T20:40:41.941Z'
      expect(Dump.first.generated_date).to eq event.start
    end

    it 'creates an event with alma job status COMPLETED_SUCCESS' do
      allow(Import::Alma).to receive(:perform_async)
      described_class.poll
      expect(Import::Alma).to have_received(:perform_async).with(instance_of(Integer), job_id)
      event = Dump.first.event
      expect(event.alma_job_status).to eq 'COMPLETED_SUCCESS'
    end
  end

  context 'when an alma job completes with errors an incremental dump job comes through' do
    let(:job_id) { '38205463100006421' }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_incremental_dump_alma_job_failed.json'))).to_json }

    it 'creates an event with alma job status COMPLETED_FAILED' do
      allow(Import::Alma).to receive(:perform_async)
      described_class.poll
      expect(Import::Alma).to have_received(:perform_async).with(instance_of(Integer), job_id)
      event = Dump.first.event
      expect(event.alma_job_status).to eq 'COMPLETED_FAILED'
    end

    it 'logs error and sends to honeybadger' do
      allow(Honeybadger).to receive(:notify)
      allow(Rails.logger).to receive(:error)
      described_class.poll
      expect(Honeybadger).to have_received(:notify).with(instance_of(AlmaDumpFactory::AlmaDumpError))
      expect(Rails.logger).to have_received(:error).with('Alma job completed with invalid status. Alma status: COMPLETED_FAILED. Job id: 38205463100006421')
    end
  end

  context 'when a ReCAP dump comes through' do
    let(:job_id) { '6587815790006421' }
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_recap_incremental_dump.json'))).to_json }

    it 'Creates an event and kicks off a background job' do
      allow(Import::Alma).to receive(:perform_async)
      described_class.poll
      expect(Import::Alma).to have_received(:perform_async).with(instance_of(Integer), job_id)

      expect(Dump.all.count).to eq 1
      expect(Dump.first.dump_type).to eq 'princeton_recap'
      event = Dump.first.event
      expect(event.message_body).to eq message_body
      expect(event.start).to eq '2021-02-08T17:03:52.894Z'
      expect(event.finish).to eq '2021-02-08T20:40:41.941Z'
      expect(Dump.first.generated_date).to eq event.start
    end
  end

  context 'when some other job comes through' do
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_other_job.json'))).to_json }

    it 'Does nothing' do
      allow(Import::Alma).to receive(:perform_async)
      described_class.poll
      expect(Import::Alma).not_to have_received(:perform_async)
      expect(Dump.all.count).to eq 0
      expect(Event.all.count).to eq 0
    end
  end
end
