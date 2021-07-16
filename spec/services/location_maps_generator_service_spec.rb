require 'rails_helper'

RSpec.describe LocationMapsGeneratorService do
  let(:service) { described_class.new(base_path: base_path) }
  let(:base_path) { './tmp/' }
  let(:locations_path) { File.join(base_path, 'locations.rb') }
  let(:location_display_path) { File.join(base_path, 'location_display.rb') }
  let(:holding_library_path) { File.join(base_path, 'holding_library.rb') }

  after do
    FileUtils.rm(locations_path) if File.exist?(locations_path)
    FileUtils.rm(location_display_path) if File.exist?(location_display_path)
    FileUtils.rm(holding_library_path) if File.exist?(holding_library_path)
  end

  describe '.generate' do
    before do
      allow(described_class).to receive(:new).and_return(service)
    end

    it 'generates location maps from data in holdings tables' do
      FactoryBot.create(:holding_location)
      described_class.generate
      expect(File.read(locations_path)).to include('location-code', 'location-label')
      expect(File.read(location_display_path)).to include('location-code', 'Firestone Library')
    end

    context 'when the holding locations table does not exist' do
      let(:logger) { instance_double(ActiveSupport::Logger) }
      let(:service) { described_class.new(base_path: base_path, logger: logger) }
      before do
        allow(logger).to receive(:warn)
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_return(false)
      end

      it 'logs the  error' do
        service.generate
        expect(logger).to have_received(:warn).with(/has not been created/)
      end
    end

    context 'when there is a database error' do
      let(:logger) { instance_double(ActiveSupport::Logger) }
      let(:service) { described_class.new(base_path: base_path, logger: logger) }
      before do
        allow(logger).to receive(:warn)
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_raise(StandardError)
      end

      it 'logs the error' do
        service.generate
        expect(logger).to have_received(:warn).with(/database error/)
      end
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
      expect(File.exist?(holding_library_path)).to be true
    end

    context 'with existing translation map files' do
      before do
        allow(FileUtils).to receive(:cp)
      end

      it 'overwrites the translation map' do
        # Create a translation map file
        File.open(locations_path, 'w')

        described_class.generate_from_templates
        expect(FileUtils).to have_received(:cp).exactly(3).times
      end
    end
  end
end
