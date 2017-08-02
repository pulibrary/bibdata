require 'rails_helper'

RSpec.describe ScsbEddJob do
  let(:fail_message) {
    '{"success": false, "screenMessage": "You Failed", "emailAddress": "foo@foo.com"}'
  }
  let(:success_message) {
    '{"itemBarcode":"32101080976242","itemOwningInstitution":"PUL","screenMessage":"Retrieval order successfully created in LAS.","success":true,"esipDataIn":null,"esipDataOut":null,"requestId":54491,"expirationDate":null,"titleIdentifier":"Syria. [Prepared by the Oxford sub-centre]","dueDate":null,"circulationStatus":null,"securityMarker":null,"feeType":null,"transactionDate":null,"holdQueueLength":"0","holdPickupDate":null,"recallDate":null,"mediaType":null,"permanentLocation":null,"currentLocation":null,"bibID":"1245180","currencyType":null,"callNumber":null,"itemType":null,"bibIds":null,"source":null,"createdDate":null,"updatedDate":null,"deletedDate":null,"patronBarcode":"2210100999999","requestingInstitution":"PUL","emailAddress":"kr2@princeton.edu","requestType":"EDD","deliveryLocation":"","requestNotes":"\n\nStart Page:  \nEnd Page:  \nVolume Number:  \nIssue:  \nArticle Author:  \nArticle/Chapter Title: test ","itemId":11028365,"username":"Joe User","isbn":null,"lccn":null,"owner":null,"deleted":false}'
  }

  it 'distributes an email message to staff when a request fails via the scsb_edd queue' do
    described_class.new.perform(fail_message)
    expect(described_class.queue_name?).to be true
    expect(described_class.queue_name).to eq('scsb_edd')
  end

  it 'distributes an email message to the requesting user when a request succeeds via the scsb_edd queue' do
    described_class.new.perform(success_message)
    expect(described_class.queue_name?).to be true
    expect(described_class.queue_name).to eq('scsb_edd')
  end
end
