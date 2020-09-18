require "rails_helper"

RSpec.describe VoyagerLookup do
  let(:lib_loc) { Locations::Library.new(label: 'Library') }
  let(:holding_loc_non_circ) { Locations::HoldingLocation.new(circulates: false, always_requestable: false, library: lib_loc, label: '') }
  let(:holding_loc_always_req) { Locations::HoldingLocation.new(circulates: false, always_requestable: true, library: lib_loc, label: '') }
  let(:holding_loc_label) { Locations::HoldingLocation.new(circulates: false, label: 'Special Room', library: lib_loc) }

  describe '#single_bib_availability' do
    it 'provides full availability' do
      bib_id = '929437'
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id => {})
      described_class.single_bib_availability(bib_id: bib_id)
      expect(VoyagerHelpers::Liberator).to have_received(:get_availability).with([bib_id], true)
    end

    it 'returns a holdings hash' do
      availability_hash = {
        "1068356" => { more_items: false, location: "rcppa", status: "Not Charged" },
        "1068357" => { more_items: false, location: "fnc", status: "Not Charged" },
        "1068358" => { more_items: false, location: "anxb", patron_group_charged: nil, status: "Not Charged" } }
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("1068356"=>{ more_items: false, location: "rcppa", status: ["Not Charged"] }, "1068357"=>{ more_items: false, location: "fnc", status: ["Not Charged"] }, "1068358"=>{ more_items: false, location: "anxb", patron_group_charged: nil, status: ["Not Charged"] })
      bib_id = '929437'
      availability = described_class.single_bib_availability(bib_id: bib_id)
      expect(availability).to eq availability_hash
    end
  end

  describe '#multiple_bib_availability' do
    it 'provides partial availability' do
      bib_id = '929437'
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id => {})
      described_class.multiple_bib_availability(bib_ids: [bib_id])
      expect(VoyagerHelpers::Liberator).to have_received(:get_availability).with([bib_id], false)
    end

    it 'returns a Hash with the bib id as key and holdings hash as value' do
      bib_id = "929437"
      holding1 = "1068356"
      holding2 = "1068357"
      availability_hash = {
        bib_id => {
          holding1 => {
            more_items: false, location: "rcppa", status: "Not Charged"
          },
          holding2 => {
            more_items: false, location: "fnc", patron_group_charged: nil, status: "Not Charged"
          }
        }
      }

      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id => { holding1 => { more_items: false, location: "rcppa", status: ["Not Charged"] }, holding2 => { more_items: false, location: "fnc", patron_group_charged: nil, status: ["Not Charged"] } })
      expect(described_class.multiple_bib_availability(bib_ids: [bib_id])).to eq availability_hash
    end

    context 'when a Voyager connection error is encountered' do
      before do
        # See https://github.com/pulibrary/marc_liberation/issues/292
        class OCIError < StandardError; end if ENV['CI']
      end

      after do
        Object.send(:remove_const, :OCIError) if ENV['CI']
      end

      it 'logs an error and returns an empty hash' do
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_raise(OCIError)
        allow(Rails.logger).to receive(:error)
        bib_id = '35345'
        expect(described_class.multiple_bib_availability(bib_ids: [bib_id])).to eq({})
        expect(Rails.logger).to have_received(:error).with("Error encountered when requesting availability status: OCIError")
      end
    end
  end

  describe 'status values' do
    context 'when given an on-order record' do
      it 'returns a status of on-order' do
        bib_id = '9173362'
        holding_id = '9051785'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id =>{ "9051785"=>{ more_items: false, location: "f", status: "On-Order 09-10-2015" } })
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to start_with('On-Order')
      end
    end

    context 'when given an on-order record with a limited access (e.g. marquand) location' do
      it 'returns a status of On-Order' do
        bib_id = '9497429'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id=>{ more_items: false, location: "sa", status: "On-Order" })
        availability = described_class.single_bib_availability(bib_id: bib_id)
        _holding, details = availability.first
        expect(details[:location]).to eq('sa')
        expect(details[:status]).to include('On-Order')
      end
    end

    context 'when the record is an on-order electronic resource' do
      it 'returns a status of On-Order' do
        bib_id = '9226664'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id=>{ more_items: false, location: "elf1", status: "On-Order" })
        availability = described_class.single_bib_availability(bib_id: bib_id)
        _holding, details = availability.first
        expect(details[:location]).to eq('elf1')
        expect(details[:status]).to eq('On-Order')
      end
    end

    context 'when the record was on-order and has been received' do
      it 'returns a status of Order Received' do
        bib_id = '9468468'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", status: "Order Received 12-16-2015" })
        availability = described_class.single_bib_availability(bib_id: bib_id)
        _holding, details = availability.first
        expect(details[:status]).to include('Order Received')
      end
    end

    context 'when given a record with an elf1 (electronic) location' do
      it 'returns a status of online' do
        bib_id = '7916044'
        holding_id = '7698138'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id => { "7698138"=>{ more_items: false, location: "elf1", status: "Online" }, "7860428"=>{ more_items: false, location: "rcpph", status: ["Not Charged"] } })
        availability = described_class.multiple_bib_availability(bib_ids: [bib_id])
        expect(availability[bib_id][holding_id][:location]).to eq('elf1')
        expect(availability[bib_id][holding_id][:status]).to eq('Online')
      end
    end

    context 'when given a record with an always_requestable location' do
      it 'returns order information status' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_always_req)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "Order Received 12-16-2015" } })
        bib_id = '4609321'
        holding_id = '4847980'
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to include('Order Received')
      end
    end

    context 'when given an available record with a non-circulating, always-requestable location' do
      it 'returns a status of on-site' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_always_req)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "On Shelf" } })
        bib_id = '4609321'
        holding_id = '4847980'
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq("On-Site")
      end
    end

    context 'when given a non-available record with a non-circulating, always-requestable location' do
      it 'returns status on-site - unavailable' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_always_req)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "Unavailable" } })
        bib_id = '4609321'
        holding_id = '4847980'
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq "On-Site - Unavailable"
      end
    end

    context 'when given a record with a non-circulating, not-always-requestable location' do
      it 'returns status Unavailable' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_non_circ)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("4609321"=>{ "4847980"=>{ more_items: false, location: "whs", status: "Unavailable" } })
        bib_id = '4609321'
        holding_id = '4847980'
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq('Unavailable')
      end
    end

    context 'a holding record with no items (e.g. an ipad)' do
      it 'returns a status of On Shelf' do
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("7617477"=>{ "7429805"=>{ more_items: false, location: "f", status: "On Shelf" }, "7429809"=>{ more_items: false, location: "sci", status: "On Shelf" } })
        bib_id = '7617477'
        holding_id = '7429805'
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq('On Shelf')
      end
    end

    context 'when an item has multiple statuses' do
      it 'returns status with highest priority' do
        bib_id = '7135944'
        holding_id = '7002641'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id =>{ "7002641"=>{ more_items: false, location: "mus", copy_number: 1, item_id: 6406359, on_reserve: "N", patron_group_charged: "LMAN", status: ["Overdue", "Lost--System Applied", "In Process"] } } )
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq('Lost--System Applied')
      end
    end
  end

  describe 'status values for items with hold request status' do
    let(:lib_recap) { Locations::Library.new(code: 'recap') }
    let(:lib_other) { Locations::Library.new(code: 'other') }
    let(:holding_recap_non_aeon) { Locations::HoldingLocation.new(aeon_location: false, library: lib_recap, label: '') }
    let(:holding_recap_aeon) { Locations::HoldingLocation.new(aeon_location: true, always_requestable: true, library: lib_recap, label: '') }
    let(:holding_non_recap) { Locations::HoldingLocation.new(library: lib_other, label: '') }
    let(:bib_id) { '35345' }
    let(:holding_id) { '39176' }
    let(:recap_non_aeon) do
      { bib_id => { holding_id => { more_items: false, location: "rcppn", status: "Hold Request" } } }
    end

    context 'when given a recap non-aeon item' do
      it 'returns status of hold request' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_recap_non_aeon)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(recap_non_aeon)
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq("Hold Request")
      end
    end

    context 'when given a recap, aeon, always-requestable item' do
      it 'returns on site status' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_recap_aeon)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(recap_non_aeon)
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq("On-Site")
      end
    end

    context 'when given a non-recap item' do
      it 'returns status of not charged' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_non_recap)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(recap_non_aeon)
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:status]).to eq("Not Charged")
      end
    end
  end

  describe 'location values' do
    context 'when the record has no temp_loc' do
      it 'returns a location display label' do
        bib_id = '9497429'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return(bib_id=>{ more_items: false, location: "sa", status: "On-Order", patron_group_charged: nil })
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_always_req)
        availability = described_class.single_bib_availability(bib_id: bib_id)
        _holding, details = availability.first
        expect(details[:temp_loc]).to be nil
        expect(details[:label]).to eq lib_loc.label
      end
    end

    context 'when the record has a temp location' do
      it 'returns a temp_loc' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_label)
        temp_loc = 'woooo'
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", temp_loc: temp_loc, patron_group_charged: "CDL", status: ["Charged"], due_date: Time.now })
        bib_id = '9468468'
        availability = described_class.single_bib_availability(bib_id: bib_id)
        _holding, details = availability.first
        expect(details[:temp_loc]).to eq(temp_loc)
      end
    end

    context 'when an item has a temp loc' do
      it 'the temp location code is mapped to the display value' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_label)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", temp_loc: 'woooo', status: ["Charged"] })
        bib_id = '9468468'
        availability = described_class.single_bib_availability(bib_id: bib_id)
        _holding, details = availability.first
        expect(details[:label]).to eq "#{holding_loc_label.library.label} - #{holding_loc_label.label}"
      end
    end

    context 'when the item has a temp location with no holding location label' do
      it 'returns the library name as a label' do
        allow(Locations::HoldingLocation).to receive(:find_by).and_return(holding_loc_non_circ)
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("9329199"=>{ more_items: false, location: "f", temp_loc: 'woooo', status: ["Charged"] })
        bib_id = '9468468'
        availability = described_class.single_bib_availability(bib_id: bib_id)
        _holding, details = availability.first
        expect(details[:label]).to eq(holding_loc_non_circ.library.label)
      end
    end

  end

  describe 'more_items values' do
    context 'a holding with more than one item' do
      it 'returns more_items: true' do
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("857469"=>{ "977093"=>{ more_items: true, location: "f", status: ["Not Charged"] }, "977094"=>{ more_items: true, location: "rcppf", status: ["Not Charged"] } })
        bib_id = '857469'
        holding_id = '977093'
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:more_items]).to eq(true)
      end
    end

    context 'a holding with 0 or 1 items' do
      it 'returns more_items: false' do
        allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return("35345"=>{ "39176"=>{ more_items: false, location: "f", status: ["Not Charged"] } })
        bib_id = '35345'
        holding_id = '39176'
        availability = described_class.multiple_bib_availability(bib_ids:[bib_id])
        expect(availability[bib_id][holding_id][:more_items]).to eq(false)
      end
    end
  end

  describe 'status label values' do

  end

  describe 'full mfhd availability array' do
    it 'returns info for all items for a given mfhd' do
      allow(VoyagerHelpers::Liberator).to receive(:get_full_mfhd_availability).and_return([
        { barcode:"32101033513878", id:282630, location:"f", copy_number:1, item_sequence_number:12, status:["Not Charged"], on_reserve:"N", item_type:"NoCirc", pickup_location_id:299, patron_group_charged: nil, pickup_location_code:"fcirc", enum:"vol.20(inc.)", chron:"1994", enum_display:"vol.20(inc.) (1994)", label:"Firestone Library" },
        { barcode:"32101024070318", id:282629, location:"f", copy_number:1, item_sequence_number:11, status:["Not Charged"], on_reserve:"N", item_type:"Gen", pickup_location_id:299, patron_group_charged: nil, pickup_location_code:"fcirc", enum:"vol.19", chron:"1993", enum_display:"vol.19 (1993)", label:"Firestone Library" },
        { barcode:"32101086430665", id:6786508, location:"f", copy_number:1, item_sequence_number:26, status:["Not Charged"], on_reserve:"N", item_type:"Gen", pickup_location_id:299, patron_group_charged: nil, pickup_location_code:"fcirc", enum:"vol. 38", chron:"2012", enum_display:"vol. 38 (2012)", label:"Firestone Library" } 
      ])
      holding_id = '282033'
      availability = described_class.single_mfhd_availability(mfhd: holding_id)
      item1 = availability[0]
      item2 = availability[1]
      expect(item1[:item_type]).to eq "NoCirc"
      expect(item1[:pickup_location_id]).to eq 299
      expect(item1[:pickup_location_code]).to eq "fcirc"
      expect(item2[:item_type]).to eq "Gen"
      expect(availability.length).to eq(3)
    end
  end
end
