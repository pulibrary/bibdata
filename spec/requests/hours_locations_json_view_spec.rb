# frozen_string_literal: true
require 'rails_helper'

describe 'HoursLocation json view', type: :request do
  it 'Renders the json template' do
    get hours_locations_path, params: { format: :json }
    expect(response).to render_template(:index)
    expect(response.content_type).to eq 'application/json'
  end

  describe 'the response body' do
    it "/hours_locations looks as we'd expect" do
      2.times { FactoryBot.create(:hours_location) }
      expected = []
      HoursLocation.all.each do |hours_location|
        attrs = {
          label: hours_location.label,
          code: hours_location.code,
          path: hours_location_path(hours_location, format: :json)
        }
        expected << attrs
      end
      get hours_locations_path, params: { format: :json }
      expect(response.body).to eq expected.to_json
    end

    it "/hours_locations/{code} looks as we'd expect" do
      hours_location = FactoryBot.create(:hours_location)
      expected = {
        label: hours_location.label,
        code: hours_location.code
      }
      get hours_location_path(hours_location), params: { format: :json }
      expect(response.body).to eq expected.to_json
    end
  end
end
