# frozen_string_literal: true

require 'rails_helper'

describe DeliveryLocation, type: :model do
  describe 'validations' do
    it 'factory produces a valid subject' do
      delivery_location = create(:delivery_location)
      expect(delivery_location.valid?).to be_truthy
    end

    %i[label address phone_number contact_email gfa_pickup staff_only pickup_location digital_location].each do |a|
      it "is not valid without a #{a}" do
        delivery_location = create(:delivery_location)
        delivery_location.send("#{a}=", nil)
        expect(delivery_location.valid?).to be_falsey
      end
    end
  end

  describe 'holding locations association' do
    it 'can have holding locations' do
      delivery_location = create(:delivery_location)
      holding_location = create(:holding_location)
      expect do
        delivery_location.holding_locations << holding_location
      end.not_to raise_error
    end

    it 'appends holding locations as expected' do
      delivery_location = create(:delivery_location)
      delivery_location.holding_locations << create(:holding_location)
      delivery_location.holding_locations << create(:holding_location)
      delivery_location.reload
      expect(delivery_location.holding_locations.count).to eq 2
    end
  end
end
