require 'rails_helper'

RSpec.describe CampusAccessExceptionsController, type: :controller do
  context "administrator logged in" do
    login_admin

    describe "#new" do
      it "shows a form for uploading exceptions" do
        get :new
        expect(response).to render_template(:new)
      end
    end

    describe "#create" do
      it "adds the exceptions" do
        CampusAccess.create(uid: 'LEARN4', employee_id: '999999999', category: 'trained')
        ENV['BIBDATA_ACCESS_DIRECTORY'] = Rails.root.join("spec", "fixtures").to_s
        ENV['BIBDATA_TRAINED_FILE_NAME'] = 'access_learn.xlsx'
        ENV["CAMPUS_ACCESS_DIRECTORY"] = '/tmp'
        additional_exceptions = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'library_access_request.xslx'))
        post :create, params: { exception_file: additional_exceptions }
        expect(response).to render_template(:new)
        expect(assigns["invalid_exceptions"]).to eq(["999999998, John Doe"])
        expect(assigns["campus_access_filename"]).to eq("#{ENV['CAMPUS_ACCESS_DIRECTORY']}/additional_campus_access.csv")
        expect(File.exist?(assigns["campus_access_filename"])).to be_truthy
      end
    end
  end

  context "regular user logged in" do
    login_user

    describe "#new" do
      it "shows a form for uploading exceptions" do
        get :new
        expect(response.response_code).to eq(403)
      end
    end

    describe "#create" do
      it "adds the exceptions" do
        post :create, params: { exception_file: 'anything' }
        expect(response.response_code).to eq(403)
      end
    end
  end

  context "no user" do
    describe "#new" do
      it "shows a form for uploading exceptions" do
        get :new
        expect(response.redirect?).to be_truthy
        expect(response.redirect_url).to eq("http://test.host/users/auth/cas")
      end
    end

    describe "#create" do
      it "adds the exceptions" do
        post :create, params: { exception_file: 'anything' }
        expect(response.redirect?).to be_truthy
        expect(response.redirect_url).to eq("http://test.host/users/auth/cas")
      end
    end
  end
end
