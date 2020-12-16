# frozen_string_literal: true

require_relative '../index'

RSpec.describe MessageHandler do
  let(:sqs_mock) { instance_double(Aws::SQS::Client) }
  let(:queue_url_mock) { instance_double(Aws::SQS::Types::GetQueueUrlResult) }

  before do
    allow(sqs_mock).to receive(:send_message)
    allow(sqs_mock).to receive(:get_queue_url).and_return(queue_url_mock)
    allow(queue_url_mock).to receive(:queue_url).and_return('url')
    allow(Aws::SQS::Client).to receive(:new).and_return(sqs_mock)
  end

  context "when the webhook sends a full dump job end event" do
    let(:alma_full_dump_message) { JSON.parse(File.read(File.join("spec", "fixtures", "alma_full_dump_message.json"))) }
    let(:event) do
      {
        "signature" => "secretstuff",
        "body" => alma_full_dump_message
      }
    end

    it "pushes an SQS notification" do
      described_class.new(event).run
      expect(sqs_mock).to have_received(:send_message).with(hash_including(message_body: alma_full_dump_message.to_json))
    end
  end

  context "when the webhook sends a bib event" do
    let(:alma_bib_message) { JSON.parse(File.read(File.join("spec", "fixtures", "alma_bib_message.json"))) }
    let(:event) do
      {
        "signature" => "secretstuff",
        "body" => alma_bib_message
      }
    end

    it "does not push an SQS notification" do
      described_class.new(event).run
      expect(sqs_mock).not_to have_received(:send_message)
    end
  end
end
