require 'rails_helper'

RSpec.describe RecapBoundwithsProcessingJob do
  let(:boundwith_ids_in_dumpfile) { ["99121886293506421", "9929455773506421", "9962646063506421"] }
  let(:missing_constituent_ids) { ["9929455783506421", "9929455793506421", "9962645993506421"] }
  let(:missing_host_ids) { ["99116515383506421"] }

  before do
    allow(RecapTransferJob).to receive(:perform_now)
  end

  describe ".perform" do
    before do
      # Cache related host and constituent records. Bibdata does not retrieve
      # these from the Alma API.
      PublishingJobFileService.new(path: "spec/fixtures/files/alma/scsb_dump_fixtures/cacheable_scsb_records.tar.gz").cache
    end

    it "creates a new boundwith dump file and caches marc records" do
      dump = FactoryBot.create(:recap_incremental_dump)
      boundwiths_file_path = described_class.perform_now(dump)
      expect(File.basename(boundwiths_file_path)).to include("recap_6836725000006421_20210401_010420[012]_boundwiths", ".xml.tar.gz")
      expect(File.exist?(boundwiths_file_path)).to eq true

      # Unzip it, get the MARC-XML
      records = dump_file_to_marc(path: boundwiths_file_path)

      ids = boundwith_ids_in_dumpfile +
            missing_constituent_ids +
            missing_host_ids

      expect(records.map { |r| r["001"].value }).to contain_exactly(*ids)

      # Constituent records are enriched with holdings from host record
      record = records.find { |r| r["001"].value == "9929455773506421" }
      expect(record["852"]["0"]).to eq "22269289940006421"
      expect(record["852"]["8"]).to eq "22269289940006421"
      expect(record["852"]["b"]).to eq "recap$pa"
      expect(record["852"]["c"]).to eq "pa"
      expect(record["852"]["h"]).to eq "3488.93344.333"

      # Constituent records are enriched with items data from host record
      expect(record["876"]["0"]).to eq "22269289940006421"
      expect(record["876"]["3"]).to be_blank
      expect(record["876"]["a"]).to eq "23269289930006421"
      expect(record["876"]["p"]).to eq "32101066958685"
      expect(record["876"]["t"]).to be_blank
      expect(record["876"]["h"]).to be_blank
      expect(record["876"]["x"]).to eq "Shared"
      expect(record["876"]["z"]).to eq "PA"
      expect(record["876"]["j"]).to eq "Not Used"
      expect(record["876"]["l"]).to eq "RECAP"
      expect(record["876"]["k"]).to eq "recap"

      # Updated records and records retrieved from the Alma API are cached
      expect(CachedMarcRecord.all.count).to eq 7

      # File is transferred to S3
      expect(RecapTransferJob).to have_received(:perform_now)
    end

    context "with a dump that has no boundwiths" do
      it "does not transfer a file to S3" do
        dump = FactoryBot.create(:recap_incremental_dump_no_boundwiths)
        described_class.perform_now(dump)
        expect(RecapTransferJob).not_to have_received(:perform_now)
      end
    end
  end
end
