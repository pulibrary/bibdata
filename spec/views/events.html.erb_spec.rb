# frozen_string_literal: true
require "rails_helper"

RSpec.describe "events/index", type: :view do
  context "events page" do
    it "lists events ordered by start asc in localtime" do
      assign(:events, [
               event1 = FactoryBot.create(:event),
               event2 = FactoryBot.create(:event, start: Time.now - 2.months, finish: Time.now - 2.months + 180, error: nil, success: true),
               event3 = FactoryBot.create(:event, start: Time.now - 1.month, finish: Time.now - 1.month + 180, error: nil, success: true)
             ])
      render
      expect(rendered).to have_css('tr.table-striped:nth-child(1) > td:nth-child(2)', text: event1.start.localtime.to_fs(:db_twelve_hour))
      expect(rendered).to have_css('tr.table-striped:nth-child(2) > td:nth-child(2)', text: event2.start.localtime.to_fs(:db_twelve_hour))
      expect(rendered).to have_css('tr.table-striped:nth-child(3) > td:nth-child(2)', text: event3.start.localtime.to_fs(:db_twelve_hour))
    end

    it "does not include Delete column for unauthenticated users" do
      assign(:events, [FactoryBot.create(:event)])
      render
      expect(rendered).not_to include "<th>Delete?</th>"
    end

    it "includes Delete column for authenticated users" do
      allow(view).to receive(:user_signed_in?) { true }
      assign(:events, [FactoryBot.create(:event)])
      render
      expect(rendered).to include "<th>Delete?</th>"
    end
  end
end
