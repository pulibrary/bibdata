require 'rails_helper'

describe OCI8 do

  let(:holding_id)  { 2281830 }
  let(:item_id)     { 23672 }
  let(:bib_id)      { 2002206 }
  let(:bib_ids)     { [3377193,4679943] }
  let(:subject)     { described_class }
  let(:conn)        { subject.new(VoyagerHelpers.config.db_user,
                                  VoyagerHelpers.config.db_password,
                                  VoyagerHelpers.config.db_name)
                    }

  describe 'liberator functions only make one oracle connection' do
    
    it '#get_availability' do
      allow(subject).to receive(:new).and_return(conn)
      expect(subject).to receive(:new).once
      VoyagerHelpers::Liberator.get_availability(bib_ids)
    end

    it '#get_bib_record' do
      allow(subject).to receive(:new).and_return(conn)
      expect(subject).to receive(:new).once
      VoyagerHelpers::Liberator.get_bib_record(bib_id)
    end

    it '#get_holding_records' do
      allow(subject).to receive(:new).and_return(conn)
      expect(subject).to receive(:new).once
      VoyagerHelpers::Liberator.get_holding_records(bib_id)
    end

    it '#get_items_for_bib' do
      allow(subject).to receive(:new).and_return(conn)
      expect(subject).to receive(:new).once
      VoyagerHelpers::Liberator.get_items_for_bib(bib_id)
    end

    it '#get_holding_record' do
      allow(subject).to receive(:new).and_return(conn)
      expect(subject).to receive(:new).once
      VoyagerHelpers::Liberator.get_holding_record(holding_id)
    end

    it '#get_items_for_holding' do
      allow(subject).to receive(:new).and_return(conn)
      expect(subject).to receive(:new).once
      VoyagerHelpers::Liberator.get_items_for_holding(holding_id)
    end

    it '#get_item' do
      allow(subject).to receive(:new).and_return(conn)
      expect(subject).to receive(:new).once
      VoyagerHelpers::Liberator.get_item(item_id)
    end

  end
end
