# frozen_string_literal: true
require "rails_helper"

RSpec.describe AlmaAdapter::Bib do
  let(:unsuppressed) { "991227850000541" }
  let(:unsuppressed_two) { "991227840000541" }
  let(:suppressed) { "99222441306421" }
  let(:suppressed_unsuppressed_ids) { ["991227850000541", "991227840000541", "99222441306421"] }
  let(:suppressed_xml) { file_fixture("alma/suppressed_#{suppressed}.xml").read }
  let(:unsuppressed_xml) { file_fixture("alma/unsuppressed_#{unsuppressed}.xml").read }
  let(:unsuppressed_suppressed) { file_fixture("alma/unsuppressed_suppressed.xml").read }
  let(:alma_marc_991227850000541) { MARC::XMLReader.new(StringIO.new(unsuppressed_xml)).first }
  let(:holdings_991227840000541) { file_fixture("alma/991227840000541_holdings.xml").read }

  before do
    allow(described_class).to receive(:apikey).and_return('TESTME')
    AlmaAdapter.config[:region] = 'ALMA'
    stub_request(:get, "https://ALMA/almaws/v1/bibs?apikey=TESTME&mms_id=#{suppressed_unsuppressed_ids.join(',')}&query%5Bexpand%5D=p_avail,e_avail,d_avail,requests")
      .to_return(status: 200, body: unsuppressed_suppressed, headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })
    stub_request(:get, "https://ALMA/almaws/v1/bibs?apikey=TESTME&mms_id=#{suppressed}&query%5Bexpand%5D=p_avail,e_avail,d_avail,requests")
      .to_return(status: 200, body: suppressed_xml, headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })
    stub_request(:get, "https://ALMA/almaws/v1/bibs?apikey=TESTME&mms_id=#{unsuppressed}&query%5Bexpand%5D=p_avail,e_avail,d_avail,requests")
      .to_return(status: 200, body: unsuppressed_xml, headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })
    stub_request(:get, "https://alma/almaws/v1/bibs/991227850000541/holdings?apikey=TESTME")
      .to_return(status: 200, body: holdings_991227840000541, headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })
  end
  describe "#get_bib_record" do
    context "when an unsuppressed bib is provided" do
      it "returns one record" do
        expect(described_class.get_bib_record(unsuppressed)['001'].value).to eq "991227850000541"
      end
    end
    context "when a suppressed bib is provided" do
      it "returns nil" do
        expect(described_class.get_bib_record(suppressed)).to be nil
      end
    end
  end

  describe "#get_bib_records" do
    context "if a string of bibs is provided" do
      it "returns multiple unsuppressed records" do
        expect(described_class.get_bib_records(suppressed_unsuppressed_ids)[0]['001'].value).to eq unsuppressed_two
        expect(described_class.get_bib_records(suppressed_unsuppressed_ids)[1]['001'].value).to eq unsuppressed
        expect(described_class.get_bib_records(suppressed_unsuppressed_ids).count).to eq 2
      end
    end
  end

  describe '#get_holding_records' do
    it "returns the holdings for a bib" do
      expect(described_class.get_holding_records(unsuppressed)).to be_a(String)
    end
  end

  describe "records with no availability" do
    it "doesn't have an AVA tag" do
      # find an alma record with no 952 from the publishing job to add it as a fixture.
    end
  end

  describe "with an alma record that has an ARK" do
    it "exposes the ark" do
      # find an alma record with an ark.princeton.edu
    end
  end

  describe "alma record with no item" do
    # it has a holding
    # it doesn't have an item. This should be checked on the Holding
    it "has a holding" do
    end
  end

  describe "alma holding with order information" do
    # alma record with a po line.
    it "displays ..." do
    end
  end

  # no need to check for a 959 in Alma. This will be a check after the index
  describe "alma holding with order information" do
    it "has a PO line" do
      # we added a PO for a holding
      # MMS ID 99227515106421 Holdings ID 2284011070006421 Item ID 2384011050006421
      # it has in the AVA $e unavailable <subfield code="e">unavailable</subfield>
      # we might want to test this on the item level or in the availability.
      # when we first added the PO line it created the item 2384011050006421 with an on order status.
      # This is different from voyager where it doesn't add an item when the user creates a PO line.
      # What does the AVA tag display after the PO is accepted.
    end
  end

  describe ".get_items_for_bib" do
    it "exists" do
      fixture_file = File.open(Rails.root.join("spec", "fixtures", "files", "alma", "bib_items_list_#{unsuppressed}.json"))
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/991227850000541/holdings/ALL/items?expand=due_date_policy,due_date&limit=100")
        .with(
          headers: {
            'Accept' => 'application/json',
            'Authorization' => 'apikey TESTME'
          }
        )
        .to_return(
          status: 200,
          headers: { "content-Type" => "application/json" },
          body: fixture_file
        )
      items_data = described_class.get_items_for_bib(unsuppressed)
      expect(items_data).to be_a Alma::BibItemSet
    end
  end
end
