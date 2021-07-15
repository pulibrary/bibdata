# frozen_string_literal: true
require 'rails_helper'

describe HoursLocation, type: :model do
  describe 'validations' do
    it 'factory creates a valid instance' do
      hours_location = FactoryBot.create(:hours_location)
      expect(hours_location.valid?).to be_truthy
    end

    %i[label code].each do |a|
      it "is not valid without a #{a}" do
        hours_location = FactoryBot.create(:hours_location)
        hours_location.send("#{a}=", nil)
        expect(hours_location.valid?).to be_falsey
      end
    end

    it 'code must be unique' do
      FactoryBot.create(:hours_location, code: 'abcd')
      expect do
        FactoryBot.create(:hours_location, code: 'abcd')
      end.to raise_error ActiveRecord::RecordInvalid
    end
  end
end
