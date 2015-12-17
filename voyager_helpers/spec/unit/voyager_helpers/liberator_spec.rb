require 'rails_helper'

describe VoyagerHelpers::Liberator do

  let(:placeholder_bib) { 12345 }
  let(:date) { Date.parse("2015-12-14T15:34:00.000-05:00") }
  let(:no_order_found) { {} }
  let(:pre_order) { [{
                      date: nil,
                      li_status: 0,
                      po_status: 0
                      }] }
  let(:approved_order) { [{
                      date: date,
                      li_status: 8,
                      po_status: 1
                      }] }
  let(:partially_rec_order) { [{
                      date: Date.parse("2015-12-16T15:34:00.000-05:00"),
                      li_status: 8,
                      po_status: 3
                      }] }
  let(:received_order) { [{
                      date: Date.parse("2015-12-15T15:34:00.000-05:00"),
                      li_status: 1,
                      po_status: 4
                      }] }

  describe '#get_order_status' do

    it 'returns nil when no order found for bib' do
      allow(described_class).to receive(:get_orders).and_return(no_order_found)
      expect(described_class.get_order_status(placeholder_bib)).to eq nil
    end
    it 'returns Pending Order for pending orders, date not included if nil' do
      allow(described_class).to receive(:get_orders).and_return(pre_order)
      expect(described_class.get_order_status(placeholder_bib)).to eq "Pending Order"
    end
    it 'returns On-Order for approved order' do
      allow(described_class).to receive(:get_orders).and_return(approved_order)
      expect(described_class.get_order_status(placeholder_bib)).to include('On-Order')
    end
    it 'returns On-Order for partially received order' do
      allow(described_class).to receive(:get_orders).and_return(partially_rec_order)
      expect(described_class.get_order_status(placeholder_bib)).to include('On-Order')
    end
    it 'returns Order Received for fully received order' do
      allow(described_class).to receive(:get_orders).and_return(received_order)
      expect(described_class.get_order_status(placeholder_bib)).to include('Order Received')
    end
    it "includes status date with order response" do
      allow(described_class).to receive(:get_orders).and_return(approved_order)
      expect(described_class.get_order_status(placeholder_bib)).to include(date.strftime('%m-%d-%Y'))
    end
  end
end
