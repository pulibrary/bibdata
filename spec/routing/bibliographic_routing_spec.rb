require "rails_helper"

RSpec.describe BibliographicController, type: :routing do
  describe "routing" do
    it "routes to #item_discharge" do
      expect(post: "/bibliographic/123/holdings/456/items/789/discharge").to route_to("bibliographic#item_discharge", mms_id: "123", holding_id: "456", item_pid: "789", format: :json)
    end
  end
end
