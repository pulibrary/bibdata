require 'rails_helper'

RSpec.describe DataSeeder do
  it 'creates DumpType and DumpFileType entries' do
    DumpType.all.map(&:destroy)
    DumpFileType.all.map(&:destroy)
    seeder = described_class.new
    seeder.generate_dump_types
    seeder.generate_dump_file_types
    expect(DumpType.count).not_to be_zero
    expect(DumpFileType.count).not_to be_zero
  end

  it 'is idempotent' do
    seeder = described_class.new
    expect { seeder.generate_dump_types }.not_to change { DumpType.count }
    expect { seeder.generate_dump_file_types }.not_to change { DumpFileType.count }
  end
end
