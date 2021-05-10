require 'rails_helper'

RSpec.describe "deprecated endpoint page", type: :system do
  describe "any deprecated endpoint" do
    it "returns 410 gone" do
      visit "/barcode/32101044947941"
      expect(page).to have_http_status(410)
      expect(page).to have_content("Deprecated endpoint")
    end
  end
end
