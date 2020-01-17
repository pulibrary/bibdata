require "rails_helper"

RSpec.describe PatronController, type: :routing do
  describe "routing" do
    describe "routes to #patron_info" do
      it "supports routes with dots in them" do
        expect(get: "/patron/ma.dee.e").to route_to("patron#patron_info", patron_id: "ma.dee.e", format: :json)
      end
      it "supports routes without in them" do
        expect(get: "/patron/asdf").to route_to("patron#patron_info", patron_id: "asdf", format: :json)
      end
    end

    describe "routes to #patron_codes" do
      it "supports routes with dots in them" do
        expect(get: "/patron/ma.dee.e/codes").to route_to("patron#patron_codes", patron_id: "ma.dee.e", format: :json)
      end
      it "supports routes without in them" do
        expect(get: "/patron/asdf/codes").to route_to("patron#patron_codes", patron_id: "asdf", format: :json)
      end
    end
  end
end
