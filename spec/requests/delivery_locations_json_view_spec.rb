# frozen_string_literal: true

require 'rails_helper'

describe 'DeliveryLocation', type: :request do
  context 'with a json view' do
    it 'Renders the json template' do
      get delivery_locations_path, params: { format: :json }
      expect(response).to render_template(:index)
      expect(response.content_type).to eq 'application/json; charset=utf-8'
    end

    describe 'the response body' do
      it "/delivery_locations looks as we'd expect" do
        create_list(:delivery_location, 2)
        expected = []
        DeliveryLocation.all.each do |delivery_location|
          attrs = {
            label: delivery_location.label,
            address: delivery_location.address,
            phone_number: delivery_location.phone_number,
            contact_email: delivery_location.contact_email,
            gfa_pickup: delivery_location.gfa_pickup,
            staff_only: delivery_location.staff_only,
            pickup_location: delivery_location.pickup_location,
            digital_location: delivery_location.digital_location,
            path: delivery_location_path(delivery_location, format: :json),
            library: {
              label: delivery_location.library.label,
              code: delivery_location.library.code,
              order: delivery_location.library.order
            }
          }
          expected << attrs
        end
        get delivery_locations_path, params: { format: :json }
        expect(response.body).to eq expected.to_json
      end

      it "/delivery_locations/{code} looks as we'd expect" do
        delivery_location = create(:delivery_location)
        expected = {
          label: delivery_location.label,
          address: delivery_location.address,
          phone_number: delivery_location.phone_number,
          contact_email: delivery_location.contact_email,
          gfa_pickup: delivery_location.gfa_pickup,
          staff_only: delivery_location.staff_only,
          pickup_location: delivery_location.pickup_location,
          digital_location: delivery_location.digital_location,
          library: {
            label: delivery_location.library.label,
            code: delivery_location.library.code,
            order: delivery_location.library.order
          }
        }
        get delivery_location_path(delivery_location), params: { format: :json }
        expect(response.body).to eq expected.to_json
      end
    end
  end

  context 'with an html view' do
    it 'Renders the html template by default' do
      get delivery_locations_path
      expect(response).to render_template(:index)
      expect(response.content_type).to eq 'text/html; charset=utf-8'
    end

    describe 'the response body' do
      it '/delivery_locations contains expected fields' do
        create_list(:delivery_location, 2)
        expected = []
        DeliveryLocation.all.each do |delivery_location|
          attrs = [
            CGI.escapeHTML(delivery_location.label),
            CGI.escapeHTML(delivery_location.address),
            delivery_location.phone_number,
            delivery_location.contact_email,
            delivery_location.gfa_pickup,
            delivery_location.staff_only,
            delivery_location.pickup_location,
            delivery_location.digital_location,
            delivery_location.library.code
          ]
          expected << attrs
        end
        expected << ['Staff only', 'Pickup Location']
        get delivery_locations_path
        expected.flatten.uniq.each { |e| expect(response.body).to include(e.to_s) }
      end

      it '/delivery_locations/{code} contains expected fields' do
        delivery_location = create(:delivery_location)
        expected = [
          CGI.escapeHTML(delivery_location.label),
          CGI.escapeHTML(delivery_location.address),
          delivery_location.phone_number,
          delivery_location.contact_email,
          delivery_location.gfa_pickup,
          delivery_location.staff_only,
          delivery_location.pickup_location,
          delivery_location.digital_location,
          delivery_location.library.code
        ]
        get delivery_location_path(delivery_location)
        expected.each { |e| expect(response.body).to include(e.to_s) }
      end
    end
  end
end
