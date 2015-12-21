require 'rails_helper'

describe VoyagerHelpers::Liberator do
  let(:placeholder_id) { 12345 }

  describe '#get_order_status' do
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

    it 'returns nil when no order found for bib' do
      allow(described_class).to receive(:get_orders).and_return(no_order_found)
      expect(described_class.get_order_status(placeholder_id)).to eq nil
    end
    it 'returns Pending Order for pending orders, date not included if nil' do
      allow(described_class).to receive(:get_orders).and_return(pre_order)
      expect(described_class.get_order_status(placeholder_id)).to eq "Pending Order"
    end
    it 'returns On-Order for approved order' do
      allow(described_class).to receive(:get_orders).and_return(approved_order)
      expect(described_class.get_order_status(placeholder_id)).to include('On-Order')
    end
    it 'returns On-Order for partially received order' do
      allow(described_class).to receive(:get_orders).and_return(partially_rec_order)
      expect(described_class.get_order_status(placeholder_id)).to include('On-Order')
    end
    it 'returns Order Received for fully received order' do
      allow(described_class).to receive(:get_orders).and_return(received_order)
      expect(described_class.get_order_status(placeholder_id)).to include('Order Received')
    end
    it "includes status date with order response" do
      allow(described_class).to receive(:get_orders).and_return(approved_order)
      expect(described_class.get_order_status(placeholder_id)).to include(date.strftime('%m-%d-%Y'))
    end
  end

  describe '#get_full_mfhd_availability' do
    let(:item_id) { 36736 }
    let(:item_barcode) { '32101005535917' }
    let(:not_charged) { 'Not Charged' }
    let(:single_volume_2_copy) { [{
                                id: item_id,
                                status: not_charged,
                                on_reserve: 'N',
                                temp_location: nil,
                                perm_location: 'f',
                                enum: nil,
                                chron: nil,
                                copy_number: 2,
                                item_sequence_number: 1,
                                status_date: '2014-05-27T06:00:19.000-05:00',
                                barcode: item_barcode
    }] }
    let(:enum_info) { 'v.2' }
    let(:limited_multivolume) { [{
                                id: item_id,
                                status: not_charged,
                                on_reserve: 'N',
                                temp_location: nil,
                                perm_location: 'num',
                                enum: enum_info,
                                chron: nil,
                                copy_number: 1,
                                item_sequence_number: 1,
                                status_date: '2014-05-27T06:00:19.000-05:00',
                                barcode: item_barcode
    }] }
    let(:volume) { 'vol. 24' }
    let(:chron_info) { 'Jan 2016' }
    let(:enum_with_chron) { [{
                                id: item_id,
                                status: not_charged,
                                on_reserve: 'N',
                                temp_location: nil,
                                perm_location: 'mus',
                                enum: volume,
                                chron: chron_info,
                                copy_number: 1,
                                item_sequence_number: 1,
                                status_date: '2014-05-27T06:00:19.000-05:00',
                                barcode: item_barcode
    }] }
    let(:temp) { 'scires' }
    let(:reserve_item) { [{
                                id: item_id,
                                status: not_charged,
                                on_reserve: 'Y',
                                temp_location: temp,
                                perm_location: 'sci',
                                enum: nil,
                                chron: nil,
                                copy_number: 1,
                                item_sequence_number: 1,
                                status_date: '2014-05-27T06:00:19.000-05:00',
                                barcode: item_barcode
    }] }
    let(:perm) { 'sciterm' }
    let(:reserve_no_temp) { [{
                                id: item_id,
                                status: not_charged,
                                on_reserve: 'Y',
                                temp_location: nil,
                                perm_location: perm,
                                enum: nil,
                                chron: nil,
                                copy_number: 1,
                                item_sequence_number: 1,
                                status_date: '2014-05-27T06:00:19.000-05:00',
                                barcode: item_barcode
    }] }

    it 'includes item id and barcode in response' do
      allow(described_class).to receive(:get_items_for_holding).and_return(single_volume_2_copy)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:id]).to eq item_id
      expect(availability[:barcode]).to eq item_barcode
    end
    it 'limited availability in limited-access location' do
      allow(described_class).to receive(:get_items_for_holding).and_return(limited_multivolume)
      allow(described_class).to receive(:limited_access_location?).and_return(true)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:status]).to eq "Limited"
    end
    it 'includes Voyager status by default in full-access location' do
      allow(described_class).to receive(:get_items_for_holding).and_return(single_volume_2_copy)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:status]).to eq not_charged
    end
    it 'includes enumeration info when present' do
      allow(described_class).to receive(:get_items_for_holding).and_return(limited_multivolume)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:enum]).to eq enum_info
    end
    it 'excludes enum when item enumeration is nil' do
      allow(described_class).to receive(:get_items_for_holding).and_return(single_volume_2_copy)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:enum]).to eq nil
    end
    it 'includes chron date with enumeration info when present' do
      allow(described_class).to receive(:get_items_for_holding).and_return(enum_with_chron)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:enum]).to include("(#{chron_info})") 
    end
    it 'includes copy number for non-reserve items if value is not 1' do
      allow(described_class).to receive(:get_items_for_holding).and_return(single_volume_2_copy)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:copy_number]).to eq 2
    end
    it 'includes copy number regardless of value for on reserve item' do
      allow(described_class).to receive(:get_items_for_holding).and_return(reserve_item)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:copy_number]).to eq 1
    end
    it 'excludes copy number for single copy non reserve item' do
      allow(described_class).to receive(:get_items_for_holding).and_return(limited_multivolume)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:copy_number]).to eq nil
    end
    it 'includes temp_location code for on reserve item' do
      allow(described_class).to receive(:get_items_for_holding).and_return(reserve_item)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:on_reserve]).to eq temp
    end
    it 'if no temp_location on reserve item location code falls back to perm_location' do
      allow(described_class).to receive(:get_items_for_holding).and_return(reserve_no_temp)
      availability = described_class.get_full_mfhd_availability(placeholder_id).first
      expect(availability[:on_reserve]).to eq perm
    end
  end
end

      def get_full_mfhd_availability(mfhd_id)
        item_availability = []
        items = get_items_for_holding(mfhd_id)
        items.each do |item|
          item_hash = {}
          if item[:on_reserve] == 'Y'
            item_hash[:on_reserve] = item[:temp_location] || item[:perm_location]
            item_hash[:copy_number] = item[:copy_number]
            item_hash[:status] = item[:status]
          else
            item_hash[:status] = limited_access_location?(item[:perm_location]) ? 'Limited' : item[:status]
            item_hash[:copy_number] = item[:copy_number] if item[:copy_number] != 1
          end
          item_hash[:barcode] = item[:barcode]
          unless item[:enum].nil?
            enum = item[:enum]
            enum << " (#{item[:chron]})" unless item[:chron].nil?
            item_hash[:enum] = enum
          end
          item_availability << item_hash
        end
        item_availability
      end