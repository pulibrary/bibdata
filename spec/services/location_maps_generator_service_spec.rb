require 'rails_helper'

RSpec.describe LocationMapsGeneratorService do
  let(:service) { described_class.new(base_path: base_path) }
  let(:base_path) { './tmp/' }
  let(:locations_path) { File.join(base_path, 'locations.rb') }
  let(:location_display_path) { File.join(base_path, 'location_display.rb') }

  after do
    FileUtils.rm(locations_path)
    FileUtils.rm(location_display_path)
  end

  describe '.generate' do
    before do
      allow(described_class).to receive(:new).and_return(service)
    end

    it 'generates location maps from data in holdings tables' do
      described_class.generate
      expect(File.exist?(locations_path)).to be true
      expect(File.exist?(location_display_path)).to be true
    end
  end

  describe '.generate_from_templates' do
    let(:locations_template_path) { File.join(base_path, 'locations.rb.tmpl') }
    let(:location_display_template_path) { File.join(base_path, 'location_display.rb.tmpl') }
    let(:holding_library_template_path) { File.join(base_path, 'holding_library.rb.tmpl') }

    before do
      File.open(locations_template_path, 'w')
      File.open(location_display_template_path, 'w')
      File.open(holding_library_template_path, 'w')
      allow(described_class).to receive(:new).and_return(service)
    end

    after do
      FileUtils.rm(locations_template_path)
      FileUtils.rm(location_display_template_path)
      FileUtils.rm(holding_library_template_path)
    end

    it 'generates location maps template files' do
      described_class.generate_from_templates
      expect(File.exist?(locations_path)).to be true
      expect(File.exist?(location_display_path)).to be true
    end
  end
end
