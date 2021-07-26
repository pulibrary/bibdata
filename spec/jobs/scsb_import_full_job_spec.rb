require 'rails_helper'

RSpec.describe ScsbImportFullJob do
  it 'creates an event' do
    allow(Scsb::PartnerUpdates).to receive(:full)

    expect { described_class.perform_now }.to change { Event.count }.by(1)
    event = Event.last

    expect(event.start).not_to be nil
    expect(event.finish).not_to be nil
    expect(event.dump).to be_a(Dump)
    expect(event.dump.dump_type).to be_a(DumpType)
    expect(event.dump.dump_type.constant).to eq 'PARTNER_RECAP_FULL'
    expect(Scsb::PartnerUpdates).to have_received(:full)
  end
end
