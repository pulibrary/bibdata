require 'rails_helper'

RSpec.describe ScsbMailer, :type => :mailer do

  context "Retrieval Request" do
    let(:args) {
      {
        "itemBarcode"=>"32101069042784",
        "itemOwningInstitution"=>"PUL",
        "screenMessage"=>"Successfully Processed Request Item",
        "success"=>true,
        "esipDataIn"=>nil,
        "esipDataOut"=>nil,
        "requestId"=>54472,
        "expirationDate"=>"01-02-2018 18:57:43",
        "titleIdentifier"=>"[No Restrictions] 2ND MURPHY-ACF INTERNATIONAL, COMPLETE BULLETIN. [RECAP]",
        "dueDate"=>"01-02-2018 18:57:43",
        "circulationStatus"=>nil,
        "securityMarker"=>nil,
        "feeType"=>nil,
        "transactionDate"=>nil,
        "holdQueueLength"=>"0",
        "holdPickupDate"=>nil,
        "recallDate"=>nil,
        "mediaType"=>nil,
        "permanentLocation"=>nil,
        "currentLocation"=>nil,
        "bibID"=>"5591956",
        "currencyType"=>nil,
        "callNumber"=>nil,
        "itemType"=>nil,
        "bibIds"=>nil,
        "source"=>nil,
        "createdDate"=>nil,
        "updatedDate"=>nil,
        "deletedDate"=>nil,
        "patronBarcode"=>"22101009999999",
        "requestingInstitution"=>"PUL",
        "emailAddress"=>"test@account.edu",
        "requestType"=>"RETRIEVAL",
        "deliveryLocation"=>"PA",
        "requestNotes"=>"",
        "itemId"=>12977183,
        "username"=>"Joe User",
        "lccn"=>nil,
        "isbn"=>nil,
        "owner"=>nil,
        "deleted"=>false
      }.with_indifferent_access
    }
    let(:mail) {
      ScsbMailer.send("request_email", args).deliver_now
    }

    it "renders the headers" do
      # expect(mail.subject).to eq()
      expect(mail.to).to eq(['test@account.edu'])
      expect(mail.from).to eq(['bah'])
    end
  end

  context "EDD Request" do
    let(:args) {
      {
        "itemBarcode"=>"32101069042784",
        "itemOwningInstitution"=>"PUL",
        "screenMessage"=>"Successfully Placed request in LAS",
        "success"=>true,
        "esipDataIn"=>nil,
        "esipDataOut"=>nil,
        "requestId"=>54472,
        "expirationDate"=>"01-02-2018 18:57:43",
        "titleIdentifier"=>"[No Restrictions] 2ND MURPHY-ACF INTERNATIONAL, COMPLETE BULLETIN. [RECAP]",
        "dueDate"=>"01-02-2018 18:57:43",
        "circulationStatus"=>nil,
        "securityMarker"=>nil,
        "feeType"=>nil,
        "transactionDate"=>nil,
        "holdQueueLength"=>"0",
        "holdPickupDate"=>nil,
        "recallDate"=>nil,
        "mediaType"=>nil,
        "permanentLocation"=>nil,
        "currentLocation"=>nil,
        "bibID"=>"5591956",
        "currencyType"=>nil,
        "callNumber"=>nil,
        "itemType"=>nil,
        "bibIds"=>nil,
        "source"=>nil,
        "createdDate"=>nil,
        "updatedDate"=>nil,
        "deletedDate"=>nil,
        "patronBarcode"=>"22101009999999",
        "requestingInstitution"=>"PUL",
        "emailAddress"=>"test@account.edu",
        "requestType"=>"RETRIEVAL",
        "deliveryLocation"=>"PA",
        "requestNotes"=>"An EDD Request",
        "itemId"=>12977183,
        "username"=>"Joe User",
        "lccn"=>nil,
        "isbn"=>nil,
        "owner"=>nil,
        "deleted"=>false
      }.with_indifferent_access
    }
    let(:mail) {
      ScsbMailer.send("edd_email", args).deliver_now
    }

    it 'has the correct email address' do

    end
  end

  context "Recall Request" do
    let(:args) {
      {
        "itemBarcode"=>"32101069042784",
        "itemOwningInstitution"=>"PUL",
        "screenMessage"=>"Successfully Processed Request Item",
        "success"=>true,
        "esipDataIn"=>nil,
        "esipDataOut"=>nil,
        "requestId"=>54472,
        "expirationDate"=>"01-02-2018 18:57:43",
        "titleIdentifier"=>"[No Restrictions] 2ND MURPHY-ACF INTERNATIONAL, COMPLETE BULLETIN. [RECAP]",
        "dueDate"=>"01-02-2018 18:57:43",
        "circulationStatus"=>nil,
        "securityMarker"=>nil,
        "feeType"=>nil,
        "transactionDate"=>nil,
        "holdQueueLength"=>"0",
        "holdPickupDate"=>nil,
        "recallDate"=>nil,
        "mediaType"=>nil,
        "permanentLocation"=>nil,
        "currentLocation"=>nil,
        "bibID"=>"5591956",
        "currencyType"=>nil,
        "callNumber"=>nil,
        "itemType"=>nil,
        "bibIds"=>nil,
        "source"=>nil,
        "createdDate"=>nil,
        "updatedDate"=>nil,
        "deletedDate"=>nil,
        "patronBarcode"=>"22101009999999",
        "requestingInstitution"=>"PUL",
        "emailAddress"=>"test@account.edu",
        "requestType"=>"RETRIEVAL",
        "deliveryLocation"=>"PA",
        "requestNotes"=>"",
        "itemId"=>12977183,
        "username"=>"Joe User",
        "lccn"=>nil,
        "isbn"=>nil,
        "owner"=>nil,
        "deleted"=>false
      }.with_indifferent_access
    }
    let(:mail) {
      ScsbMailer.send("recak_email", args).deliver_now
    }
  end
end
