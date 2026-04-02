require 'rails_helper'

RSpec.describe AlmaAdapter::AlmaItem do
  let(:item_pa_committed_to_retain_not_in_retention_reason) do
    Alma::BibItem.new(
      'item_data' => {
        'library' => {
          'desc' => 'ReCAP', 'value' => 'recap'
        },
        'location' => {
          'desc' => 'rcppa: RECAP',
          'value' => 'pa'
        },
        'committed_to_retain' => {
          'value' => 'true', 'desc' => 'Yes'
        },
        'retention_reason' => {
          'value' => 'NotInRetention', 'desc' => 'NotInRetention Imprints', 'retention_note' => ''
        }
      }
    )
  end

  def build_item_committed_to_retain(retention_reason:)
    Alma::BibItem.new(
      'item_data' => {
        'library' => {
          'desc' => 'ReCAP', 'value' => 'recap'
        },
        'location' => {
          'desc' => 'rcppa: RECAP',
          'value' => 'pa'
        },
        'committed_to_retain' => {
          'value' => 'true', 'desc' => 'Yes'
        },
        'retention_reason' => {
          'value' => retention_reason, 'desc' => retention_reason, 'retention_note' => ''
        }
      }
    )
  end

  def build_item(code:, retention_reason:)
    Alma::BibItem.new(
      'item_data' => {
        'library' => {
          'desc' => 'ReCAP', 'value' => 'recap'
        },
        'location' => {
          'desc' => code,
          'value' => code
        },
        'committed_to_retain' => {
          'value' => 'false', 'desc' => 'No'
        },
        'retention_reason' => {
          'value' => retention_reason, 'desc' => retention_reason, 'retention_note' => ''
        }
      }
    )
  end

  describe '#recap_customer_code' do
    context 'When location starts with x' do
      it 'returns PG' do
        item = described_class.new(
          build_item(code: 'xx', retention_reason: 'other')
        )

        expect(item.recap_customer_code).to eq 'PG'
      end
    end

    context "When location doesn't start with X" do
      it 'capitalizes the code' do
        item = described_class.new(
          build_item(code: 'pa', retention_reason: 'other')
        )

        expect(item.recap_customer_code).to eq 'PA'
      end
    end
  end

  describe '#group_designation' do
    context 'It returns Committed' do
      %w[ReCAPItalianImprints IPLCBrill ReCAPSACAP].each do |retention_reason|
        it "when it's committed to retain and in committed retention reason #{retention_reason}" do
          item = described_class.new(
            build_item_committed_to_retain(retention_reason:)
          )
          expect(item.group_designation).to eq 'Committed'
        end
      end
    end

    context "When it's committed to retain and not in committed retention reason" do
      it 'is checking the location' do
        item = described_class.new(item_pa_committed_to_retain_not_in_retention_reason)
        expect(item.group_designation).to eq 'Shared'
      end
    end

    context "When it's not committed to retain and in committed retention reason" do
      %w[ReCAPItalianImprints IPLCBrill ReCAPSACAP].each do |retention_reason|
        %w[pv pa gp qk pf].each do |code|
          context "when retention reason is #{retention_reason} and not committed to retain and location is #{code}" do
            it 'is checking the location and returns Shared' do
              item = described_class.new(
                build_item(code:, retention_reason:)
              )
              expect(item.group_designation).to eq 'Shared'
            end
          end
        end
      end
      %w[ReCAPItalianImprints IPLCBrill ReCAPSACAP].each do |retention_reason|
        %w[jq pe pg ph pq qb ql qv qx].each do |code|
          context "when retention reason is #{retention_reason} and not committed to retain and location is #{code}" do
            it 'is checking the location and returns Private' do
              item = described_class.new(
                build_item(code:, retention_reason:)
              )

              expect(item.group_designation).to eq 'Private'
            end
          end
        end
      end
    end
  end

  describe '#recap_use_restriction' do
    %w[pj pk pl pm pn pt].each do |code|
      context "When location is #{code}" do
        it 'returns In Library Use' do
          item = described_class.new(
            build_item(code:, retention_reason: 'other')
          )

          expect(item.recap_use_restriction).to eq 'In Library Use'
          expect(item.group_designation).to eq 'Private'
        end
      end
    end
    ['pv'].each do |code|
      context "When location is #{code}" do
        it 'returns In Library Use' do
          item = described_class.new(
            build_item(code:, retention_reason: 'other')
          )

          expect(item.recap_use_restriction).to eq 'In Library Use'
          expect(item.group_designation).to eq 'Shared'
        end
      end
    end
    %w[pb ph ps pw pz xc xg xm xn xp xr xw xx xgr xcr phr xrr xmr].each do |code|
      context "When location is #{code}" do
        it 'returns Supervised Use' do
          item = described_class.new(
            build_item(code:, retention_reason: 'other')
          )

          expect(item.recap_use_restriction).to eq 'Supervised Use'
          expect(item.group_designation).to eq 'Private'
        end
      end
    end
  end

  describe 'status' do
    let(:item_work_order_acq) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '99122455086806421' },
        'holding_data' => { 'holding_id' => '22477860740006421' },
        'item_data' => {
          'pid' => '23477860730006421',
          'base_status' => { 'value' => '0', 'desc' => 'Item not in place' },
          'process_type' => { 'value' => 'WORK_ORDER_DEPARTMENT', 'desc' => 'In Process' },
          'work_order_type' => { 'value' => 'AcqWorkOrder', 'desc' => 'Acquisitions and Cataloging' },
          'work_order_at' => { 'value' => 'AcqDepttechserv', 'desc' => 'Acquisitions and Cataloging' },
          'requested' => false
        }
      )
    end

    let(:item_work_order_coll_dev) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '99122455086806421' },
        'holding_data' => { 'holding_id' => '22477860740006421' },
        'item_data' => {
          'pid' => '23477860730006421',
          'base_status' => { 'value' => '0', 'desc' => 'Item not in place' },
          'process_type' => { 'value' => 'WORK_ORDER_DEPARTMENT', 'desc' => 'In Process' },
          'work_order_type' => { 'value' => 'CollDev', 'desc' => 'Collection Development Office' },
          'work_order_at' => { 'value' => 'CollDev', 'desc' => 'Collection Development Office' },
          'requested' => false
        }
      )
    end

    let(:item_work_order_holdings_mgmt) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '99122455086806421' },
        'holding_data' => { 'holding_id' => '22477860740006421' },
        'item_data' => {
          'pid' => '23477860730006421',
          'base_status' => { 'value' => '1', 'desc' => 'Item in place' },
          'process_type' => { 'value' => 'TRANSIT', 'desc' => 'Transit' },
          'work_order_type' => { 'value' => 'HMT', 'desc' => 'Holdings Management' },
          'work_order_at' => { 'value' => 'HMT', 'desc' => 'Holdings Management' },
          'requested' => false
        }
      )
    end

    let(:item_process_type_acq) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '9939075533506421' },
        'holding_data' => { 'holding_id' => '22194161030006421' },
        'item_data' => {
          'pid' => '23194161020006421',
          'base_status' => { 'value' => '0', 'desc' => 'Item not in place' },
          'process_type' => { 'value' => 'HOLDSHELF', 'desc' => 'Hold Shelf' },
          'requested' => false
        }
      )
    end
    let(:item_work_order_firestone_circ) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '997626913506421' },
        'holding_data' => { 'holding_id' => '22580669980006421' },
        'item_data' => {
          'pid' => '23580669780006421',
          'base_status' => { 'value' => '0', 'desc' => 'Item not in place' },
          'process_type' => { 'value' => 'WORK_ORDER_DEPARTMENT', 'desc' => 'In Process' },
          'work_order_type' => { 'value' => 'Firestone', 'desc' => 'Firestone Circulation' },
          'work_order_at' => { 'value' => 'DEFAULT_CIRC_DESK-Firestone', 'desc' => 'Firestone Circulation Desk' },
          'requested' => false
        }
      )
    end

    let(:item_base_status_in_place) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '9939075533506421' },
        'holding_data' => { 'holding_id' => '22194161030006421' },
        'item_data' => { 'pid' => '23194161020006421', 'process_type' => { 'value' => '' }, 'base_status' => { 'value' => '1', 'desc' => 'Item in place' }, 'requested' => false }
      )
    end

    let(:item_base_status_not_in_place) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '9939075533506421' },
        'holding_data' => { 'holding_id' => '22194161030006421' },
        'item_data' => { 'pid' => '23194161020006421', 'process_type' => { 'value' => 'ACQ', 'desc' => 'Acquisition' }, 'base_status' => { 'value' => '0', 'desc' => 'Item not in place' }, 'requested' => false }
      )
    end

    let(:item_no_process_type_and_requested) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '99126856502706421' },
        'holding_data' => { 'holding_id' => '22965530090006421' },
        'item_data' => { 'pid' => '23965530080006421', 'process_type' => { 'value' => '' }, 'base_status' => { 'value' => '1', 'desc' => 'Item in place' }, 'requested' => true }
      )
    end

    let(:item_in_place_no_process_type_not_requested) do
      Alma::BibItem.new(
        'bib_data' => { 'mms_id' => '99126856502706421' },
        'holding_data' => { 'holding_id' => '22965530090006421' },
        'item_data' => { 'pid' => '23965530080006421', 'process_type' => { 'value' => '' }, 'base_status' => { 'value' => '1', 'desc' => 'Item in place' }, 'requested' => false }
      )
    end

    context 'when process_type value is WORK_ORDER_DEPARTMENT - item with work order in' do
      it 'Acquisitions and Cataloging has code Unavailable and label Acquisitions and Cataloging' do
        item = described_class.new(item_work_order_acq)
        status = item.calculate_status
        expect(status[:code]).to eq 'Unavailable'
        expect(status[:label]).to eq 'Acquisitions and Cataloging'
        expect(status[:source]).to eq 'work_order'
      end

      it 'Firestone Circulation has code Unavailable and label Firestone Circulation' do
        item = described_class.new(item_work_order_firestone_circ)
        status = item.calculate_status
        expect(status[:code]).to eq 'Unavailable'
        expect(status[:label]).to eq 'Firestone Circulation'
        expect(status[:source]).to eq 'work_order'
      end
    end

    # Process type values: ACQ CLAIM_RETURNED_LOAN HOLDSHELF ILL LOAN LOST_ILL LOST_LOAN LOST_LOAN_AND_PAID MISSING REQUESTED TECHNICAL TRANSIT TRANSIT_TO_REMOTE_STORAGE WORK_ORDER_DEPARTMENT
    { 'ACQ' => 'Acquisition', 'CLAIM_RETURNED_LOAN' => 'Claimed Returned', 'HOLDSHELF' => 'Hold Shelf', 'ILL' => 'Resource Sharing Request', 'LOAN' => 'Loan', 'LOST_ILL' => 'Lost Resource Sharing Item', 'LOST_LOAN' => 'Lost', 'LOST_LOAN_AND_PAID' => 'Lost and paid', 'MISSING' => 'Missing', 'REQUESTED' => 'Requested', 'TECHNICAL' => 'Technical - Migration', 'TRANSIT' => 'Transit', 'TRANSIT_TO_REMOTE_STORAGE' => 'In Transit to Remote Storage', 'WORK_ORDER_DEPARTMENT' => 'In Process' }.each do |process_type_value, process_type_label|
      context "when process_type value is #{process_type_value} - items with work order in" do
        { 'AcqWorkOrder' => 'Acquisitions and Cataloging', 'CollDev' => 'Collection Development Office', 'HMT' => 'Holdings Management', 'Pres' => 'Preservation' }.each do |work_order_type_value, work_order_type_desc|
          let(:item_process_types) do
            Alma::BibItem.new(
              'bib_data' => { 'mms_id' => '99122455086806421' },
              'holding_data' => { 'holding_id' => '22477860740006421' },
              'item_data' => {
                'pid' => '23477860730006421',
                'base_status' => { 'value' => '1', 'desc' => 'Item in place' },
                'process_type' => { 'value' => process_type_value, 'desc' => process_type_label },
                'work_order_type' => { 'value' => work_order_type_value, 'desc' => work_order_type_desc },
                'work_order_at' => { 'value' => 'HMT', 'desc' => 'Holdings Management' },
                'requested' => false
              }
            )
          end

          it "#{work_order_type_desc} has status code and label Unavailable" do
            item = described_class.new(item_process_types)
            status = item.calculate_status
            expect(status[:code]).to eq 'Unavailable'
            expect(status[:label]).to eq 'Unavailable'
            expect(status[:source]).to eq 'process_type'
          end
        end
      end
    end

    context 'when there is no process_type value' do
      it 'and the item is requested, it has status code and label Unavailable' do
        item = described_class.new(item_no_process_type_and_requested)
        status = item.calculate_status
        expect(status[:code]).to eq 'Unavailable'
        expect(status[:label]).to eq 'Unavailable'
        expect(status[:source]).to eq 'requested_true'
      end

      it 'the item is not requested and Item is in Place it has status code and label Unavailable' do
        item = described_class.new(item_in_place_no_process_type_not_requested)
        status = item.calculate_status
        expect(status[:code]).to eq 'Available'
        expect(status[:label]).to eq 'Item in place'
        expect(status[:source]).to eq 'base_status'
      end
    end

    it 'Handles items with base status (in place)' do
      item = described_class.new(item_base_status_in_place)
      expect(item.calculate_status[:code]).to eq 'Available'
    end

    it 'Handles items with base status (not in place)' do
      item = described_class.new(item_base_status_not_in_place)
      expect(item.calculate_status[:code]).to eq 'Unavailable'
    end
  end
end
