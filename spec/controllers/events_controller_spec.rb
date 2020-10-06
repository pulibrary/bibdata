# frozen_string_literal: true
require "rails_helper"

RSpec.describe EventsController do
  describe "#index" do
    render_views
    before do
      create_list(:event, 51)
    end

    context "with more than 50 records" do
      it "paginates records" do
        get :index
        expect(response.body).to have_xpath("//*[@class='pagination']//a[text()='2']")
        expect(response).to have_http_status(200)
      end

      it "has a second page with 1 record" do
        get(:index, params: { page: 2 })
        expect(response).to have_http_status(200)
        expect(response.body).to have_xpath("//tbody//tr", count: 1)
      end
    end
  end
end
