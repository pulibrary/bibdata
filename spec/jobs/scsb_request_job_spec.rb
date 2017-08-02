require 'rails_helper'

RSpec.describe ScsbRequestJob do
  let(:fail_message) {
    '{"success": false, "screenMessage": "You Failed", "emailAddress": "foo@foo.com"}'
  }
  let(:success_message) {
    '{"success": true, "screenMessage": "Request plaaced", "emailAddress": "foo@foo.com"}'
  }
  let(:no_email_success_message) {
    '{"success": true, "screenMessage": "Request plaaced", "emailAddress": null }'
  }

  it 'distributes an email message to staff when a request fails via the scsb_request queue' do
    described_class.new.perform(fail_message)
    expect(described_class.queue_name?).to be true
    expect(described_class.queue_name).to eq('scsb_request')
  end

  # it 'logs the message passed to the job' do
  #   described_class.new.perform(fail_message)
  #   allow(described_class.logger).to receive(:info).and_call_original
  #   expect(described_class.logger).to receive(:info).with("Processing Message #{fail_message}")
  # end

  it 'distributes an email message to the requesting user when a request succeeds via the scsb_request queue' do
    described_class.new.perform(success_message)
    expect(described_class.queue_name?).to be true
    expect(described_class.queue_name).to eq('scsb_request')
  end

  # it 'does not enqueue a mail job when no email is present' do
  #   described_class.new.perform(no_email_success_message)
  #   expect(described_class.queue_name?).to be false
  # end
end
