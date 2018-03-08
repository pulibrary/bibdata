require 'rails_helper'

RSpec.describe ScsbMailer, type: :mailer do

  context "Retrieval Request" do
    let(:args) do
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
    end
    let(:mail) do
      ScsbMailer.send("request_email", args).deliver_now
    end

    it "renders the headers" do
      expect(mail.to).to eq(['test@account.edu'])
      expect(mail.from).to eq([I18n.t('scsb.default_from')])
      expect(mail.subject).to eq( I18n.t('scsb.request.email_subject'))
    end

    it "renders the body" do
      expect(mail.body.encoded).to have_content args["titleIdentifier"]
      expect(mail.body.encoded).to have_content args["itemBarcode"]
    end

    it 'provides a link to your library account' do
      expect(mail.body.encoded).to have_content 'https://pulsearch.princeton.edu/account'
    end
  end

  context "Failed Retrieval Request" do
    let(:args) do
      {
        "itemBarcode": "32101101392320",
        "itemOwningInstitution": "PUL",
        "screenMessage": "ILS Exception : Item barcode not found.",
        "success": false,
        "esipDataIn": nil,
        "esipDataOut": nil,
        "requestId": 54538,
        "expirationDate": nil,
        "titleIdentifier": "[In Library Use] L'ABBAYE SAINT-PIERRE DE MOZAC. ARCHITECTURE, DECORS ET HISTOIRE D?UN SITE MONASTIQUE (VIIE-XXE SIECLE) / [RECAP]",
        "dueDate": nil,
        "circulationStatus": nil,
        "securityMarker": nil,
        "feeType": nil,
        "transactionDate": nil,
        "holdQueueLength": "0",
        "holdPickupDate": nil,
        "recallDate": nil,
        "mediaType": nil,
        "permanentLocation": nil,
        "currentLocation": nil,
        "bibID": "10153117",
        "currencyType": nil,
        "callNumber": nil,
        "itemType": nil,
        "bibIds": nil,
        "source": nil,
        "createdDate": nil,
        "updatedDate": nil,
        "deletedDate": nil,
        "patronBarcode": "22101009999999",
        "requestingInstitution": "PUL",
        "emailAddress": "foo@princeton.edu",
        "requestType": "RETRIEVAL",
        "deliveryLocation": "PJ",
        "requestNotes": "ILS Exception : Item barcode not found.",
        "itemId": 13655298,
        "username": "Joe User",
        "isbn": nil,
        "lccn": nil,
        "owner": nil,
        "deleted": false
      }
    end

    let(:mail) do
      ScsbMailer.send("error_email", args).deliver_now
    end

    it "renders the headers" do
      expect(mail.to).to eq([I18n.t('scsb.default_error_to')])
      expect(mail.from).to eq([I18n.t('scsb.default_from')])
      expect(mail.subject).to eq( I18n.t('scsb.default_error_subject'))
    end

    it "renders the body" do
      expect(mail.body.encoded).to have_content "#{args["screenMessage"]}"
    end
  end

  context "EDD Request" do
    let(:args) do
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
        "requestType"=>"EDD",
        "deliveryLocation"=>"PA",
        "requestNotes"=>"requestNotes\":\"User: Test From Kevin.\\n\\nStart Page: 22 \\nEnd Page: 50 \\nVolume Number: 1 \\nIssue: 2 \\nArticle Author:  \\nArticle/Chapter Title: Chapter Two \"",
        "itemId"=>12977183,
        "username"=>"Joe User",
        "lccn"=>nil,
        "isbn"=>nil,
        "owner"=>nil,
        "deleted"=>false
      }.with_indifferent_access
    end
    let(:mail) do
      ScsbMailer.send("edd_email", args).deliver_now
    end

    it "renders the headers" do
      expect(mail.to).to eq(['test@account.edu'])
      expect(mail.from).to eq([I18n.t('scsb.default_from')])
      expect(mail.subject).to eq( I18n.t('scsb.edd.email_subject'))
    end

    it "renders the body" do
      expect(mail.body.encoded).to have_content args["requestNotes"]
      expect(mail.body.encoded).to have_content args["titleIdentifier"]
      expect(mail.body.encoded).to have_content args["itemBarcode"]
    end
  end

  context "Recall Request" do
    let(:args) do
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
    end
    let(:mail) do
      ScsbMailer.send("recall_email", args).deliver_now
    end

    it "renders the headers" do
      expect(mail.to).to eq(['test@account.edu'])
      expect(mail.from).to eq([I18n.t('scsb.default_from')])
    end

    it "renders the body" do
      expect(mail.body.encoded).to have_content args["requestNotes"]
      expect(mail.body.encoded).to have_content args["titleIdentifier"]
      expect(mail.body.encoded).to have_content args["itemBarcode"]
    end
  end
end
