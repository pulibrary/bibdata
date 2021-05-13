require 'rails_helper'

RSpec.describe 'db:seed' do
  it 'creates DumpType and DumpFileType entries' do
    DumpType.all.map(&:destroy)
    DumpFileType.all.map(&:destroy)
    Rails.application.load_seed
    expect(DumpType.count).not_to be_zero
    expect(DumpFileType.count).not_to be_zero
  end

  it 'is idempotent' do
    Rails.application.load_seed
    expect { Rails.application.load_seed }.not_to change { DumpType.count }
    expect { Rails.application.load_seed }.not_to change { DumpFileType.count }
  end
end
