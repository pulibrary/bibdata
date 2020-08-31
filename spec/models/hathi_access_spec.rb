require 'rails_helper'

RSpec.describe HathiAccess, type: :model do
  describe "status" do
    it "can only be ALLOW or DENY" do
      ha = HathiAccess.new(status: "allowed")
      ha.valid?
      expect(ha.errors.details.keys).to include (:status)
      ha.status = "ALLOW"
      ha.valid?
      expect(ha.errors.details.keys).not_to include (:status)
    end
  end

  describe "origin" do
    it "can only be CUL or PUL" do
      ha = HathiAccess.new(origin: "Columbia")
      ha.valid?
      expect(ha.errors.details.keys).to include (:origin)
      ha.origin = "CUL"
      ha.valid?
      expect(ha.errors.details.keys).not_to include (:origin)
    end
  end
end
