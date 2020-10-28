# frozen_string_literal: true
require "rails_helper"

RSpec.describe EventsController, type: :controller do
  describe "#index" do
    context "events page" do
      it "lists the events, ordered by start asc in UTC" do
        event2 = FactoryBot.create(:event, start: Time.now - 3.months, finish: Time.now - 3.months + 180, error: nil, success: true)
        event3 = FactoryBot.create(:event, start: Time.now - 2.months, finish: Time.now - 2.months + 180, error: nil, success: true)
        event1 = FactoryBot.create(:event)
        event4 = FactoryBot.create(:event, start: Time.now - 1.month, finish: Time.now - 1.month + 180, error: nil, success: true)
        get :index
        expect(assigns(:events)).to eq([event2, event3, event4, event1])
        expect(response.status).to eq(200)
      end
    end
  end
end
