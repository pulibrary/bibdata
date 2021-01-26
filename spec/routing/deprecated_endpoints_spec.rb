require "rails_helper"

RSpec.describe "deprecated endpoint routes", type: :routing do
  describe "barcode/:barcode" do
    it "routes to 410 gone" do
      expect(get: "/barcode/32101044947941").to route_to("deprecated_endpoints#gone", barcode: "32101044947941")
    end
  end
end
