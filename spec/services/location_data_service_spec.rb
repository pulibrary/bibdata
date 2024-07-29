require 'rails_helper'

RSpec.describe LocationDataService, type: :service do
  let(:service) { described_class.new }
  let(:locations_path) { Rails.root.join('spec', 'fixtures', 'files', 'alma', 'locations') }
  let(:holding_locations) { File.join(locations_path, 'holding_locations.json') }
  let(:delivery_locations) { File.join(locations_path, 'delivery_locations.json') }
  let(:libraries) { File.join(locations_path, 'libraries.json') }

  before do
    allow(MARC_LIBERATION_CONFIG).to receive(:[]).with("location_files_dir").and_return(locations_path)
    described_class.delete_existing_and_repopulate
    @delivery_lewis = DeliveryLocation.find_by(gfa_pickup: "PN")
  end

  describe "#delete_existing_and_repopulate" do
    it "deletes existing data and populates library and location data from json" do
      arch_library = Library.find_by(code: 'arch')
      arch_stacks = HoldingLocation.find_by(code: 'arch$stacks')
      annex_stacks = HoldingLocation.find_by(code: 'annex$stacks')
      delivery_location_pf = DeliveryLocation.find_by(gfa_pickup: 'PF')
      eastasian_hy = HoldingLocation.find_by(code: 'eastasian$hy')
      firestone_seref = HoldingLocation.find_by(code: 'firestone$seref')
      firestone_se = HoldingLocation.find_by(code: 'firestone$se')
      firestone_secw = HoldingLocation.find_by(code: 'firestone$secw')
      firestone_ssrcfo = HoldingLocation.find_by(code: 'firestone$ssrcfo')
      firestone_ssrcdc = HoldingLocation.find_by(code: 'firestone$ssrcdc')
      firestone_pres = HoldingLocation.find_by(code: 'firestone$pres')
      firestone_isc = HoldingLocation.find_by(code: 'firestone$isc')
      lewis_serial = HoldingLocation.find_by(code: 'lewis$serial')
      marquand_pv = HoldingLocation.find_by(code: 'marquand$pv')
      mudd_scamudd = HoldingLocation.find_by(code: 'mudd$scamudd')
      rare_xmr = HoldingLocation.find_by(code: 'rare$xmr')
      rare_scactsn = HoldingLocation.find_by(code: 'rare$scactsn')
      rare_scagax = HoldingLocation.find_by(code: 'rare$scagax')
      rare_scamss = HoldingLocation.find_by(code: 'rare$scamss')
      rare_scawa = HoldingLocation.find_by(code: 'rare$scawa')
      rare_scaex = HoldingLocation.find_by(code: 'rare$scaex')
      rare_scahsvm = HoldingLocation.find_by(code: 'rare$scahsvm')
      rare_scathx = HoldingLocation.find_by(code: 'rare$scathx')
      rare_xrr = HoldingLocation.find_by(code: 'rare$xrr')
      recap_gp = HoldingLocation.find_by(code: 'recap$gp')
      stokes_spia = HoldingLocation.find_by(code: 'stokes$spia')
      stokes_spr = HoldingLocation.find_by(code: 'stokes$spr')

      expect(delivery_location_pf.pickup_location).to be true
      expect(Library.count).to eq 18
      expect(HoldingLocation.count).to eq 83
      expect(arch_library.label).to eq 'Architecture Library'
      expect(annex_stacks.label).to eq 'Stacks'
      expect(arch_stacks.open).to be true
      expect(annex_stacks.open).to be false
      expect(eastasian_hy.label).to eq ''
      expect(firestone_secw.label).to eq 'Scribner Library: Common Works Collection'
      expect(firestone_seref.label).to eq 'Scribner Library: Reference'
      expect(firestone_se.label).to eq 'Scribner Library'
      expect(firestone_isc.label).to eq 'Indigenous Studies Collection'
      expect(firestone_ssrcfo.open).to be true
      expect(firestone_ssrcfo.requestable).to be false
      expect(firestone_ssrcfo.always_requestable).to be false
      expect(firestone_ssrcdc.open).to be true
      expect(firestone_ssrcdc.requestable).to be false
      expect(firestone_ssrcdc.always_requestable).to be false
      expect(firestone_isc.always_requestable).to be false
      expect(firestone_isc.requestable).to be true
      expect(firestone_isc.fulfillment_unit).to eq('General')
      expect(firestone_pres.label).to eq 'Preservation Office: Contact preservation@princeton.edu'
      expect(lewis_serial.label).to eq 'Lewis Library - Serials (Off-Site)'
      expect(marquand_pv.remote_storage).to eq 'recap_rmt'
      expect(marquand_pv.label).to eq 'Remote Storage (ReCAP): Marquand Library Use Only'
      expect(marquand_pv.open).to be false
      expect(mudd_scamudd.requestable).to be false
      expect(rare_xmr.requestable).to be false
      expect(rare_scactsn.requestable).to be false
      expect(rare_scagax.requestable).to be false
      expect(rare_scamss.requestable).to be false
      expect(rare_scawa.requestable).to be false
      expect(rare_scaex.requestable).to be false
      expect(rare_scahsvm.requestable).to be false
      expect(rare_scathx.requestable).to be false
      expect(recap_gp.remote_storage).to eq 'recap_rmt'
      expect(stokes_spia.label).to eq 'Wallace Hall (SPIA)'
      expect(stokes_spr.label).to eq 'Wallace Hall (SPR)'
    end
    context "Plasma Library" do
      plasma_location_codes = ["index", "la", "li", "nb", "ps", "rdr", "ref", "rr", "serial", "stacks", "theses"]
      plasma_location_codes.each do |code|
        it "plasma location #{code} is open and have delivery location only Lewis" do
          plasma_location = HoldingLocation.find_by(code: "plasma$#{code}")
          expect(plasma_location.open).to be true
          expect(plasma_location.delivery_locations.count).to eq 1
          expect(plasma_location.delivery_locations.first).to eq(@delivery_lewis)
        end
      end
    end
    it "firestone$pf does not circulate and delivers only to Firestone Library Microforms" do
      firestone_pf = HoldingLocation.find_by(code: 'firestone$pf')
      delivery_microforms = DeliveryLocation.find_by(gfa_pickup: 'PF')
      expect(firestone_pf.circulates).to be false
      expect(firestone_pf.delivery_locations.count).to eq 1
      expect(firestone_pf.delivery_locations.first).to eq(delivery_microforms)
      expect(firestone_pf.label).to eq('Remote Storage (ReCAP): Firestone Library Use Only')
    end
    it "annex$noncirc circulates to the branch libraries" do
      non_circ = HoldingLocation.find_by(code: 'annex$noncirc')
      delivery_firestone = DeliveryLocation.find_by(gfa_pickup: 'PA')
      @delivery_lewis = DeliveryLocation.find_by(gfa_pickup: 'PN')
      expect(non_circ.circulates).to be true
      expect(non_circ.delivery_locations.count).to eq 12
      expect(non_circ.delivery_locations).to include(delivery_firestone)
      expect(non_circ.delivery_locations).to include(@delivery_lewis)
    end
    it "Locations with fulfillment_unit: Reserves are not requestable" do
      arch_res3hr = HoldingLocation.find_by(code: 'arch$res3hr')
      eastasian_reserve = HoldingLocation.find_by(code: 'eastasian$reserve')

      expect(arch_res3hr.fulfillment_unit).to eq 'Reserves'
      expect(arch_res3hr.requestable).to eq false
      expect(eastasian_reserve.fulfillment_unit).to eq 'Reserves'
      expect(eastasian_reserve.requestable).to eq false
    end

    it "creates SCSB locations" do
      scsbnypl_record = HoldingLocation.find_by(code: 'scsbnypl')
      scsbhl_record = HoldingLocation.find_by(code: 'scsbhl')
      scsbcul_record = HoldingLocation.find_by(code: 'scsbcul')
      delivery_location_scsbcul = DeliveryLocation.all.find(scsbcul_record.delivery_location_ids.first)
      delivery_location_scsbhl = DeliveryLocation.all.find(scsbhl_record.delivery_location_ids.first)
      delivery_location_scsbnypl = DeliveryLocation.all.find(scsbnypl_record.delivery_location_ids.first)

      expect(delivery_location_record(scsbnypl_record).label).to eq 'Firestone Circulation Desk'
      expect(delivery_location_record(scsbnypl_record).gfa_pickup).to eq 'QX'
      expect(delivery_location_record(scsbhl_record).label).to eq 'Firestone Circulation Desk'
      expect(delivery_location_record(scsbcul_record).label).to eq 'Firestone Circulation Desk'
      expect(scsbcul_record.recap_electronic_delivery_location).to be true
      expect(scsbcul_record.remote_storage).to eq 'recap_rmt'
      expect(scsbhl_record.remote_storage).to eq 'recap_rmt'
      expect(scsbnypl_record.remote_storage).to eq 'recap_rmt'
      expect(scsbcul_record.label).to eq 'Remote Storage'
      expect(scsbcul_record.label).to eq 'Remote Storage'
      expect(scsbhl_record.label).to eq 'Remote Storage'
    end

    it "deletes existing delivery locations table and populates new from json file" do
      Library.find_by(code: 'annex')
    end

    it "sets a static ID" do
      # Run a second time to ensure idempotency.

      location = DeliveryLocation.find_by(gfa_pickup: "PW")

      expect(location.id).to eq 3
      expect(location.label).to eq "Architecture Library"
      new_location = FactoryBot.create(:delivery_location)
      expect(new_location.id).to eq 31
    end

    describe "new recap locations" do
      it "they have recap_edd true and holding_library same as library" do
        location_arch_pw = HoldingLocation.find_by(code: 'arch$pw')
        location_engineer_pt = HoldingLocation.find_by(code: 'engineer$pt')
        location_firestone_pb = HoldingLocation.find_by(code: 'firestone$pb')
        location_lewis_pn = HoldingLocation.find_by(code: 'lewis$pn')
        location_marquand_pj = HoldingLocation.find_by(code: 'marquand$pj')
        location_mendel_pk = HoldingLocation.find_by(code: 'mendel$pk')
        location_rare_xw = HoldingLocation.find_by(code: 'rare$xw')

        expect(location_arch_pw.recap_electronic_delivery_location).to be true
        expect(location_engineer_pt.recap_electronic_delivery_location).to be true
        expect(location_firestone_pb.recap_electronic_delivery_location).to be true
        expect(location_firestone_pb.label).to eq("Remote Storage (ReCAP): Firestone Library Use Only")
        expect(location_lewis_pn.recap_electronic_delivery_location).to be true
        expect(location_marquand_pj.recap_electronic_delivery_location).to be true
        expect(location_mendel_pk.recap_electronic_delivery_location).to be true
        expect(location_engineer_pt.holding_library.label).to eq location_engineer_pt.library.label
        expect(location_arch_pw.holding_library.label).to eq location_arch_pw.library.label
        expect(location_firestone_pb.holding_library.label).to eq location_firestone_pb.library.label
        expect(location_lewis_pn.holding_library.label).to eq location_lewis_pn.library.label
        expect(location_marquand_pj.holding_library.label).to eq location_marquand_pj.library.label
        expect(location_rare_xw.holding_library.label).to eq location_rare_xw.library.label
        expect(location_mendel_pk.holding_library.label).to eq location_mendel_pk.library.label
      end
      it "Engineer$pt has delivery location only PT" do
        location_engineer_pt = HoldingLocation.find_by(code: 'engineer$pt')
        expect(location_engineer_pt.delivery_locations.count).to eq(1)
        expect(location_engineer_pt.delivery_locations.first.gfa_pickup).to eq('PT')
      end
      it "new recap location rare$xw has recap_edd false" do
        location_rare_xw = HoldingLocation.find_by(code: 'rare$xw')
        expect(location_rare_xw.recap_electronic_delivery_location).to be false
      end
    end
  end

  def delivery_location_record(value)
    DeliveryLocation.all.find(value.delivery_location_ids.first)
  end
end
