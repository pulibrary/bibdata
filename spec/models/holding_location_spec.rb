# frozen_string_literal: true
require 'rails_helper'

describe HoldingLocation, type: :model do
  describe 'validations' do
    it 'factory produces a valid subject' do
      holding_location = FactoryBot.create(:holding_location)
      expect(holding_location.valid?).to be_truthy
    end

    %i[code aeon_location recap_electronic_delivery_location
       open requestable always_requestable circulates].each do |a|
      it "is not valid without a #{a}" do
        holding_location = FactoryBot.create(:holding_location)
        holding_location.send("#{a}=", nil)
        expect(holding_location.valid?).to be_falsey
      end
    end

    it 'is valid without a label' do
      holding_location = FactoryBot.create(:holding_location)
      holding_location.send('label=', nil)
      expect(holding_location.valid?).to eq true
    end

    it 'is valid without a remote_storage' do
      holding_location = FactoryBot.create(:holding_location)
      holding_location.send('remote_storage=', nil)
      expect(holding_location.valid?).to eq true
    end

    it 'code must be unique' do
      FactoryBot.create(:holding_location, code: 'abc')
      expect do
        FactoryBot.create(:holding_location, code: 'abc')
      end.to raise_error ActiveRecord::RecordInvalid
    end

    it 'must have a library associated with it' do
      expect do
        FactoryBot.create(:holding_location, library: nil)
      end.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'holding library association' do
    it 'can have a holding library' do
      holding_location = FactoryBot.create(:holding_location)
      holding_library = FactoryBot.create(:library)
      expect do
        holding_location.update(holding_library: holding_library)
      end.not_to raise_error
    end
  end

  describe 'delivery locations association' do
    it 'can have delivery locations' do
      holding_location = FactoryBot.create(:holding_location)
      delivery_location = FactoryBot.create(:delivery_location)
      expect do
        holding_location.delivery_locations << delivery_location
      end.not_to raise_error
    end

    it 'appends delivery locations as expected' do
      holding_location = FactoryBot.create(:holding_location)
      3.times do
        holding_location.delivery_locations << FactoryBot.create(:delivery_location)
      end
      expect(holding_location.delivery_locations.count).to eq 3
    end

    it 'associates all non-staff-only delivery locations by default' do
      2.times { FactoryBot.create(:delivery_location, staff_only: false) }
      FactoryBot.create(:delivery_location, staff_only: true)
      holding_location = FactoryBot.create(:holding_location)
      expect(holding_location.delivery_locations.count).to eq 2
    end
  end
end
