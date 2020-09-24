# frozen_string_literal: true
require "rails_helper"

RSpec.describe Alma::Bib do
  let(:bibs) { "991227850000541, 991227840000541, 991227830000541, 99222441306421" }
  let(:unsuppressed_991227850000541) { "991227850000541" }
  let(:suppressed_99222441306421) { "99222441306421" }
  let(:suppressed_unsuppressed_ids) { "991227850000541,991227840000541,99222441306421" }
  let(:unsuppressed_xml_991227850000541) { file_fixture("alma/unsuppressed_#{unsuppressed_991227850000541}.xml").read }
  let(:unsuppressed_suppressed) { file_fixture("alma/unsuppressed_suppressed.xml").read }
  let(:suppressed_xml_99222441306421) { file_fixture("alma/suppressed_#{suppressed_99222441306421}.xml").read }
  let(:alma_marc_991227850000541) { MARC::XMLReader.new(StringIO.new(unsuppressed_xml_991227850000541)).first }
  let(:holdings_991227840000541) { file_fixture("alma/991227840000541_holdings.xml").read }
  # let(:holdings_record) { MARC::XMLReader.new(StringIO.new(holdings_991227840000541)).first }
  let(:unsuppressed_xml) { file_fixture("alma/unsuppressed.xml").read }
  let(:records) { [] }
  let(:alma_records) { file_fixture("alma/alma_three_records.xml").read }
  let(:alma_marc_records) { MARC::XMLReader.new(StringIO.new(alma_records)).select {|record| records << record} }

  before do
    Alma.config[:bibs_read_only] = 'TESTME'
    Alma.config[:region]='ALMA'
    stub_request(:get, "https://ALMA/almaws/v1/bibs?apikey=TESTME&mms_id=991227850000541,991227840000541,99222441306421&query%5Bexpand%5D=p_avail,e_avail,d_avail,requests").
       to_return(status: 200, body: unsuppressed_suppressed, headers: {
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Type'=>'application/xml;charset=UTF-8',
        'Accept' => 'application/xml',
        'User-Agent'=>'Faraday v1.0.1',
        'Apikey' => 'TESTME'
      })
    stub_request(:get, "https://ALMA/almaws/v1/bibs?apikey=TESTME&mms_id=#{suppressed_99222441306421}&query%5Bexpand%5D=p_avail,e_avail,d_avail,requests").
       to_return(status: 200, body: suppressed_xml_99222441306421, headers: {
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Type'=>'application/xml;charset=UTF-8',
        'Accept' => 'application/xml',
        'User-Agent'=>'Faraday v1.0.1',
        'Apikey' => 'TESTME'
      })
    stub_request(:get, "https://ALMA/almaws/v1/bibs?apikey=TESTME&mms_id=#{unsuppressed_991227850000541}&query%5Bexpand%5D=p_avail,e_avail,d_avail,requests").
         to_return(status: 200, body: unsuppressed_xml_991227850000541, headers: {
         'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'Content-Type'=>'application/xml;charset=UTF-8',
         'Accept' => 'application/xml',
         'User-Agent'=>'Faraday v1.0.1',
         'Apikey' => 'TESTME'
       })
  end
  describe "#get_bib_record" do
    context "if one bib is provided" do
      it "returns one record" do
        expect(described_class.get_bib_record(unsuppressed_991227850000541)['001'].value).to eq "991227850000541"
      end
    end
    context "if an array of bibs is provided" do
      it "returns multiple unsuppressed records" do
        expect(described_class.get_bib_record(suppressed_unsuppressed_ids)[0]['001'].value).to eq "991227840000541"
        expect(described_class.get_bib_record(suppressed_unsuppressed_ids)[1]['001'].value).to eq "991227850000541"
        expect(described_class.get_bib_record(suppressed_unsuppressed_ids).count).to eq 2
      end
    end
  end
  describe "#ids_remove_spaces" do
    it "removes the spaces from the ids" do
      expect(described_class.ids_remove_spaces(ids: bibs)).to eq "991227850000541,991227840000541,991227830000541,99222441306421"
    end
  end

  describe '#get_holding_records' do
    it "returns the holdings for a bib" do
      allow(described_class).to receive(:get_holding_records).with(unsuppressed_991227850000541).and_return(holdings_991227840000541)
      expect(described_class.get_holding_records(unsuppressed_991227850000541)).to be_a(String)
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
    # it doesn't have an item. This should be checked on the Alma::Holding
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
end
