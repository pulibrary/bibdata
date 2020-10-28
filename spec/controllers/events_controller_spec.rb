# frozen_string_literal: true
require "rails_helper"

RSpec.describe EventsController, type: :controller do
  describe "#index" do
    context "events page" do
      it "lists the events, ordered by start asc in UTC" do
        event1 = FactoryBot.create(:event)
        event2 = FactoryBot.create(:event, start: "2019-09-08 03:00:00", finish: "2019-09-08 20:00:00", error: nil, success: true, created_at: "2019-09-08 20:00:00", updated_at: "2019-09-08 20:00:00")
        event3 = FactoryBot.create(:event, start: "2019-11-07 03:00:00", finish: "2019-11-07 20:00:00", error: nil, success: true, created_at: "2019-11-07 20:00:00", updated_at: "2019-11-07 20:00:00")
        event4 = FactoryBot.create(:event, start: "2019-12-07 03:00:00", finish: "2019-12-07 20:00:00", error: nil, success: true, created_at: "2019-12-07 20:00:00", updated_at: "2019-12-07 20:00:00")
        get :index
        expect(assigns(:events)).to eq([event2, event3, event4, event1])
        expect(response.status).to eq(200)
      end
    end
  end
end
