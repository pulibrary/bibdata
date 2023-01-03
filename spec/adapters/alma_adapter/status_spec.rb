require 'rails_helper'

RSpec.describe AlmaAdapter::Status do
  let(:status) { described_class.new(bib:, holding:, aeon:) }
  let(:bib_id) { '9963575053506421' }
  let(:bib) { Alma::Bib.new(mms_id: bib_id) }
  let(:library_code) { 'rare' }
  let(:location_code) { 'hsvm' }
  let(:availability) { 'available' }
  let(:holding) do
    {
      "holding_id" => "22726823980006421",
      "institution" => "01PRI_INST",
      "library_code" => library_code,
      "location" => "Manuscripts",
      "call_number" => "Islamic Manuscripts, Garrett no. 337L",
      "availability" => availability,
      "total_items" => "1",
      "non_available_items" => "1",
      "location_code" => location_code,
      "call_number_type" => "8",
      "priority" => "1",
      "library" => "Special Collections",
      "inventory_type" => "physical"
    }
  end
  let(:aeon) { false }

  describe '#to_s' do
    context 'with an aeon item' do
      let(:aeon) { true }
      context 'that is available' do
        let(:availability) { 'available' }

        it 'gives On-site Access' do
          expect(status.to_s).to eq('On-site Access')
        end
      end
      context 'that is unavailable' do
        let(:availability) { 'unavailable' }

        it 'gives unavailable' do
          expect(status.to_s).to eq('Unavailable')
        end
      end
    end
    context 'with an on-site location' do
      let(:aeon) { false }
      let(:library_code) { 'lewis' }
      let(:location_code) { 'map' }

      context 'that is available' do
        let(:availability) { 'available' }

        it 'gives On-site Access' do
          expect(status.to_s).to eq('On-site Access')
        end
      end
      context 'that is unavailable' do
        let(:availability) { 'unavailable' }

        it 'gives unavailable' do
          expect(status.to_s).to eq('Unavailable')
        end
      end
    end
    context 'with an off-site location' do
      let(:aeon) { false }
      let(:library_code) { 'firestone' }
      let(:location_code) { 'stacks' }

      context 'that is available' do
        let(:availability) { 'available' }

        it 'gives Available' do
          expect(status.to_s).to eq('Available')
        end
      end
      context 'that is unavailable' do
        let(:availability) { 'unavailable' }

        it 'gives unavailable' do
          expect(status.to_s).to eq('Unavailable')
        end
      end
    end
    context 'with an availability of check_holdings' do
      let(:availability) { 'check_holdings' }

      it 'gives Some items not available' do
        expect(status.to_s).to eq('Some items not available')
      end
    end
  end
end
