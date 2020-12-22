require 'rails_helper'

RSpec.describe "CampusAccessException", type: :request do
  describe "link to exceptions" do
    it "has a login link and no link to the exceptions" do
      get '/'
      expect(response.status).to be(200)
      expect(response.body).not_to include("Add Access Exceptions")
      expect(response.body).to include("Login")
    end

    context "signed in user" do
      before do
        sign_in FactoryBot.create(:user)
      end

      it "has a logout link and no link to the exceptions" do
        get '/'
        expect(response.status).to be(200)
        expect(response.body).not_to include("Add Access Exceptions")
        expect(response.body).to include("Logout")
      end
    end

    context "signed in admin user" do
      before do
        sign_in FactoryBot.create(:admin)
      end

      it "has a logout link and a link to the exceptions" do
        get '/'
        expect(response.status).to be(200)
        expect(response.body).to include("Add Access Exceptions")
        expect(response.body).to include("Logout")
      end
    end
  end
end
