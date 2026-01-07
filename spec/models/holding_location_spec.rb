# frozen_string_literal: true

require 'rails_helper'

describe HoldingLocation, type: :model do
  describe 'validations' do
    it 'factory produces a valid subject' do
      holding_location = create(:holding_location)
      expect(holding_location.valid?).to be_truthy
    end

    %i[code aeon_location recap_electronic_delivery_location
       open requestable always_requestable circulates].each do |a|
      it "is not valid without a #{a}" do
        holding_location = create(:holding_location)
        holding_location.send("#{a}=", nil)
        expect(holding_location.valid?).to be_falsey
      end
    end

    it 'is valid without a label' do
      holding_location = create(:holding_location)
      holding_location.send(:label=, nil)
      expect(holding_location.valid?).to be true
    end

    it 'is valid without a remote_storage' do
      holding_location = create(:holding_location)
      holding_location.send(:remote_storage=, nil)
      expect(holding_location.valid?).to be true
    end

    it 'code must be unique' do
      create(:holding_location, code: 'abc')
      expect do
        create(:holding_location, code: 'abc')
      end.to raise_error ActiveRecord::RecordInvalid
    end

    it 'must have a library associated with it' do
      expect do
        create(:holding_location, library: nil)
      end.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'holding library association' do
    it 'can have a holding library' do
      holding_location = create(:holding_location)
      holding_library = create(:library)
      expect do
        holding_location.update(holding_library:)
      end.not_to raise_error
    end
  end

  describe 'delivery locations association' do
    it 'can have delivery locations' do
      holding_location = create(:holding_location)
      delivery_location = create(:delivery_location)
      expect do
        holding_location.delivery_locations << delivery_location
      end.not_to raise_error
    end

    it 'appends delivery locations as expected' do
      holding_location = create(:holding_location)
      3.times do
        holding_location.delivery_locations << create(:delivery_location)
      end
      expect(holding_location.delivery_locations.count).to eq 3
    end

    it 'associates all non-staff-only delivery locations by default' do
      create_list(:delivery_location, 2, staff_only: false)
      create(:delivery_location, staff_only: true)
      holding_location = create(:holding_location)
      expect(holding_location.delivery_locations.count).to eq 2
    end
  end
end
