require "rails_helper"

RSpec.describe "deprecated endpoint routes", type: :routing do
  describe "barcode/:barcode" do
    it "routes to 410 gone" do
      expect(get: "/barcode/32101044947941").to route_to("deprecated_endpoints#gone", barcode: "32101044947941")
    end
  end

  describe "codes/:location" do
    it "routes to 410 gone" do
      expect(get: "/codes/architecture").to route_to("deprecated_endpoints#gone", location: "architecture")
    end
  end

  describe "holdings" do
    it "routes to 410 gone" do
      expect(get: "/holdings").to route_to("deprecated_endpoints#gone")
    end
  end

  describe "holdings/:holding_id" do
    it "routes to 410 gone" do
      expect(get: "/holdings/1234").to route_to("deprecated_endpoints#gone", holding_id: "1234")
    end
  end

  describe "holdings/:holding_id/items" do
    it "routes to 410 gone" do
      expect(get: "/holdings/1234/items").to route_to("deprecated_endpoints#gone", holding_id: "1234")
    end
  end

  describe "items" do
    it "routes to 410 gone" do
      expect(get: "/items").to route_to("deprecated_endpoints#gone")
    end
  end

  describe "items/:item_id" do
    it "routes to 410 gone" do
      expect(get: "/items/1234").to route_to("deprecated_endpoints#gone", item_id: "1234")
    end
  end

  describe "patron/:patron_id/codes" do
    it "routes to 410 gone" do
      expect(get: "/patron/bbird/codes").to route_to("deprecated_endpoints#gone", patron_id: "bbird")
    end

    it "still accepts routes with dots in them" do
      expect(get: "/patron/ma.dee.e/codes").to route_to("deprecated_endpoints#gone", patron_id: "ma.dee.e")
    end
  end

  describe "courses" do
    it "routes to 410 gone" do
      expect(get: "/courses").to route_to("deprecated_endpoints#gone")
    end
  end

  # get "/bib_ids", to: 'courses#bibs', defaults: { format: :json }
  describe "bib_ids" do
    it "routes to 410 gone" do
      expect(get: "/bib_ids").to route_to("deprecated_endpoints#gone")
    end
  end
end
