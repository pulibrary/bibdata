require 'rails_helper'

RSpec.describe ScsbRecallJob do
  let(:fail_message) do
    '{"success": false, "screenMessage": "You Failed", "emailAddress": "foo@foo.com"}'
  end
  let(:success_message) do
    '{"success": true, "screenMessage": "Request plaaced", "emailAddress": "foo@foo.com"}'
  end

  it 'distributes an email message to staff when a request fails' do
    described_class.new.perform(fail_message)
    expect(described_class.queue_name?).to be true
    expect(described_class.queue_name).to eq('scsb_recall')
  end

  it 'distributes an email message to the requesting user when a request succeeds' do
    described_class.new.perform(success_message)
    expect(described_class.queue_name?).to be true
    expect(described_class.queue_name).to eq('scsb_recall')
  end
end
