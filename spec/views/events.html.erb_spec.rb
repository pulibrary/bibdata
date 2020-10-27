# frozen_string_literal: true
require "rails_helper"

RSpec.describe "events/index", type: :view do
  context "events page" do
    it "lists events ordered by start asc in localtime" do
      assign(:events, [
               event1 = FactoryBot.create(:event),
               event2 = FactoryBot.create(:event, start: "2019-09-08 03:00:00", finish: "2019-09-08 20:00:00", error: nil, success: true, created_at: "2019-09-08 20:00:00", updated_at: "2019-09-08 20:00:00"),
               event3 = FactoryBot.create(:event, start: "2019-11-07 03:00:00", finish: "2019-11-07 20:00:00", error: nil, success: true, created_at: "2019-11-07 20:00:00", updated_at: "2019-11-07 20:00:00")
             ])
      render
      expect(rendered).to have_css('tr.table-striped:nth-child(1) > td:nth-child(1)', text: event1.start.localtime.to_s(:db_twelve_hour))
      expect(rendered).to have_css('tr.table-striped:nth-child(2) > td:nth-child(1)', text: event2.start.localtime.to_s(:db_twelve_hour))
      expect(rendered).to have_css('tr.table-striped:nth-child(3) > td:nth-child(1)', text: event3.start.localtime.to_s(:db_twelve_hour))
    end
  end
end
