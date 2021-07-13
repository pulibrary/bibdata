# frozen_string_literal: true
require "rails_helper"

RSpec.describe "dumps/show", type: :view do
  context "dump show page" do
    it "includes " do
      assign(:dump, FactoryBot.create(:full_dump))
      render
      response = JSON.parse(rendered)
      expect(response["type"]).to eq "all_records"
      expect(response["generated_date"]).to eq "2021-07-13T11:00:00.000Z"
    end
  end
end
