require 'rails_helper'

RSpec.describe AlmaAdapter::AlmaItem do
  let(:item_pa_committed_to_retain_not_in_retention_reason) do
    Alma::BibItem.new(
      "item_data" => {
        "library" => {
          "desc" => "ReCAP", "value" => "recap"
        },
        "location" => {
          "desc" => "rcppa: RECAP",
          "value" => "pa"
        },
        "committed_to_retain" => {
          "value" => "true", "desc" => "Yes"
        },
        "retention_reason" => {
          "value" => "NotInRetention", "desc" => "NotInRetention Imprints", "retention_note" => ""
        }
      }
    )
  end

  def build_item_committed_to_retain(retention_reason:)
    Alma::BibItem.new(
      "item_data" => {
        "library" => {
          "desc" => "ReCAP", "value" => "recap"
        },
        "location" => {
          "desc" => "rcppa: RECAP",
          "value" => "pa"
        },
        "committed_to_retain" => {
          "value" => "true", "desc" => "Yes"
        },
        "retention_reason" => {
          "value" => retention_reason, "desc" => retention_reason, "retention_note" => ""
        }
      }
    )
  end

  def build_item(code:, retention_reason:)
    Alma::BibItem.new(
      "item_data" => {
        "library" => {
          "desc" => "ReCAP", "value" => "recap"
        },
        "location" => {
          "desc" => code,
          "value" => code
        },
        "committed_to_retain" => {
          "value" => "false", "desc" => "No"
        },
        "retention_reason" => {
          "value" => retention_reason, "desc" => retention_reason, "retention_note" => ""
        }
      }
    )
  end

  describe "#recap_customer_code" do
    context "When location starts with x" do
      it "returns PG" do
        item = described_class.new(
          build_item(code: "xx", retention_reason: "other")
        )

        expect(item.recap_customer_code).to eq "PG"
      end
    end
    context "When location doesn't start with X" do
      it "capitalizes the code" do
        item = described_class.new(
          build_item(code: "pa", retention_reason: "other")
        )

        expect(item.recap_customer_code).to eq "PA"
      end
    end
  end

  describe "#group_designation" do
    context "It returns Committed" do
      ['ReCAPItalianImprints', 'IPLCBrill', 'ReCAPSACAP'].each do |retention_reason|
        it "when it's committed to retain and in committed retention reason #{retention_reason}" do
          item = described_class.new(
            build_item_committed_to_retain(retention_reason:)
          )
          expect(item.group_designation).to eq "Committed"
        end
      end
    end
    context "When it's committed to retain and not in committed retention reason" do
      it "is checking the location" do
        item = described_class.new(item_pa_committed_to_retain_not_in_retention_reason)
        expect(item.group_designation).to eq "Shared"
      end
    end
    context "When it's not committed to retain and in committed retention reason" do
      ['ReCAPItalianImprints', 'IPLCBrill', 'ReCAPSACAP'].each do |retention_reason|
        ['pv', 'pa', 'gp', 'qk', 'pf'].each do |code|
          context "when retention reason is #{retention_reason} and not committed to retain and location is #{code}" do
            it "is checking the location and returns Shared" do
              item = described_class.new(
                build_item(code:, retention_reason:)
              )
              expect(item.group_designation).to eq "Shared"
            end
          end
        end
      end
      ['ReCAPItalianImprints', 'IPLCBrill', 'ReCAPSACAP'].each do |retention_reason|
        ['jq', 'pe', 'pg', 'ph', 'pq', 'qb', 'ql', 'qv', 'qx'].each do |code|
          context "when retention reason is #{retention_reason} and not committed to retain and location is #{code}" do
            it "is checking the location and returns Private" do
              item = described_class.new(
                build_item(code:, retention_reason:)
              )

              expect(item.group_designation).to eq "Private"
            end
          end
        end
      end
    end
  end

  describe "#recap_use_restriction" do
    ["pj", "pk", "pl", "pm", "pn", "pt"].each do |code|
      context "When location is #{code}" do
        it "returns In Library Use" do
          item = described_class.new(
            build_item(code:, retention_reason: 'other')
          )

          expect(item.recap_use_restriction).to eq "In Library Use"
          expect(item.group_designation).to eq "Private"
        end
      end
    end
    ["pv"].each do |code|
      context "When location is #{code}" do
        it "returns In Library Use" do
          item = described_class.new(
            build_item(code:, retention_reason: 'other')
          )

          expect(item.recap_use_restriction).to eq "In Library Use"
          expect(item.group_designation).to eq "Shared"
        end
      end
    end
    ["pb", "ph", "ps", "pw", "pz", "xc", "xg", "xm", "xn", "xp", "xr", "xw", "xx", "xgr", "xcr", "phr", "xrr", "xmr"].each do |code|
      context "When location is #{code}" do
        it "returns Supervised Use" do
          item = described_class.new(
            build_item(code:, retention_reason: 'other')
          )

          expect(item.recap_use_restriction).to eq "Supervised Use"
          expect(item.group_designation).to eq "Private"
        end
      end
    end
  end

  describe "#cdl?" do
    context "When there is no work order type" do
      it "flags false" do
        item = described_class.new(
          build_item(code: "pa", retention_reason: 'other')
        )

        expect(item.cdl?).to eq false
      end
    end

    context "When the work order type is CDL" do
      it "flags true" do
        item = described_class.new(
          Alma::BibItem.new(
            "item_data" => {
              "library" => {
                "desc" => "ReCAP", "value" => "recap"
              },
              "location" => {
                "desc" => "pa",
                "value" => "pa"
              },
              "work_order_type" => {
                "value" => "CDL",
                "desc" => "Controlled Digital Lending"
              }
            }
          )
        )

        expect(item.cdl?).to eq true
      end
    end
  end

  describe "status" do
    let(:item_work_order_acq) do
      Alma::BibItem.new(
        "bib_data" => { "mms_id" => "99122455086806421" },
        "holding_data" => { "holding_id" => "22477860740006421" },
        "item_data" => {
          "pid" => "23477860730006421",
          "base_status" => { "value" => "0", "desc" => "Item not in place" },
          "process_type" => { "value" => "WORK_ORDER_DEPARTMENT", "desc" => "In Process" },
          "work_order_type" => { "value" => "AcqWorkOrder", "desc" => "Acquisitions and Cataloging" },
          "work_order_at" => { "value" => "AcqDepttechserv", "desc" => "Acquisitions and Cataloging" }
        }
      )
    end

    let(:item_work_order_coll_dev) do
      Alma::BibItem.new(
        "bib_data" => { "mms_id" => "99122455086806421" },
        "holding_data" => { "holding_id" => "22477860740006421" },
        "item_data" => {
          "pid" => "23477860730006421",
          "base_status" => { "value" => "0", "desc" => "Item not in place" },
          "process_type" => { "value" => "WORK_ORDER_DEPARTMENT", "desc" => "In Process" },
          "work_order_type" => { "value" => "CollDev", "desc" => "Collection Development Office" },
          "work_order_at" => { "value" => "CollDev", "desc" => "Collection Development Office" }
        }
      )
    end

    let(:item_work_order_holdings_mgmt) do
      Alma::BibItem.new(
        "bib_data" => { "mms_id" => "99122455086806421" },
        "holding_data" => { "holding_id" => "22477860740006421" },
        "item_data" => {
          "pid" => "23477860730006421",
          "base_status" => { "value" => "1", "desc" => "Item in place" },
          "process_type" => { "value" => "TRANSIT", "desc" => "Transit" },
          "work_order_type" => { "value" => "HMT", "desc" => "Holdings Management" },
          "work_order_at" => { "value" => "HMT", "desc" => "Holdings Management" }
        }
      )
    end

    let(:item_process_type_acq) do
      Alma::BibItem.new(
        "bib_data" => { "mms_id" => "9939075533506421" },
        "holding_data" => { "holding_id" => "22194161030006421" },
        "item_data" => {
          "pid" => "23194161020006421",
          "base_status" => { "value" => "0", "desc" => "Item not in place" },
          "process_type" => { "value" => "ACQ", "desc" => "Acquisition" }
        }
      )
    end

    let(:item_base_status_in_place) do
      Alma::BibItem.new(
        "bib_data" => { "mms_id" => "9939075533506421" },
        "holding_data" => { "holding_id" => "22194161030006421" },
        "item_data" => { "pid" => "23194161020006421", "base_status" => { "value" => "1", "desc" => "Item in place" } }
      )
    end

    let(:item_base_status_not_in_place) do
      Alma::BibItem.new(
        "bib_data" => { "mms_id" => "9939075533506421" },
        "holding_data" => { "holding_id" => "22194161030006421" },
        "item_data" => { "pid" => "23194161020006421", "base_status" => { "value" => "0", "desc" => "Item not in place" } }
      )
    end

    it "Handles items with work order in acquisitions" do
      item = described_class.new(item_work_order_acq)
      status = item.calculate_status
      expect(status[:code]).to eq "Not Available"
    end

    it "Handles items with work order in collection development" do
      item = described_class.new(item_work_order_coll_dev)
      status = item.calculate_status
      expect(status[:code]).to eq "Not Available"
    end

    it "Handles items with work order in holdings management" do
      item = described_class.new(item_work_order_holdings_mgmt)
      status = item.calculate_status
      expect(status[:code]).to eq "Not Available"
    end
    it "Handles items with process type in acquisitions" do
      item = described_class.new(item_process_type_acq)
      status = item.calculate_status
      expect(status[:code]).to eq "Not Available"
    end

    it "Handles items with base status (in place)" do
      item = described_class.new(item_base_status_in_place)
      expect(item.calculate_status[:code]).to eq "Available"
    end

    it "Handles items with base status (not in place)" do
      item = described_class.new(item_base_status_not_in_place)
      expect(item.calculate_status[:code]).to eq "Not Available"
    end
  end
end
