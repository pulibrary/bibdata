require 'rails_helper'

RSpec.describe RecapDumpProcessingJob do
  let(:boundwith_ids_in_dumpfile) { ["99121886293506421", "9929455773506421", "9962646063506421"] }
  let(:missing_constituent_ids_1) { ["9929455783506421", "9929455793506421"] }
  let(:missing_host_ids) { ["99116515383506421"] }
  let(:missing_constituent_ids_2) { ["9962645993506421"] }

  before do
    stub_alma_ids(ids: missing_constituent_ids_1, status: 200, fixture: "scsb_dump_fixtures/constituent_response1")
    stub_alma_ids(ids: missing_host_ids, status: 200, fixture: "scsb_dump_fixtures/host_response")
    stub_alma_ids(ids: missing_constituent_ids_2, status: 200, fixture: "scsb_dump_fixtures/constituent_response2")
  end

  describe ".perform" do
    after do
      FileUtils.rm_rf Dir.glob("#{MARC_LIBERATION_CONFIG['data_dir']}/*")
    end

    it "enqueues a RecapDumpFileProcessingJob for each DumpFile" do
      dump = FactoryBot.create(:recap_incremental_dump)

      expect { described_class.perform_now(dump) }.to have_enqueued_job(RecapDumpFileProcessingJob).twice
    end

    it "creates a new boundwith dump file and caches marc records" do
      dump = FactoryBot.create(:recap_incremental_dump)
      expect { described_class.perform_now(dump) }.to change { dump.reload.dump_files.count }.by(1)
      boundwiths_file = dump.dump_files.last
      expect(boundwiths_file.dump_file_type.constant).to eq "RECAP_RECORDS"
      expect(File.basename(boundwiths_file.path)).to eq "recap_6836725000006421_20210401_010420[012]_boundwiths.xml.tar.gz"
      expect(File.exist?(boundwiths_file.path)).to eq true

      # Unzip it, get the MARC-XML
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(boundwiths_file.path))
      tar_extract.tap(&:rewind)
      content = StringIO.new(tar_extract.first.read)
      records = MARC::XMLReader.new(content, external_encoding: 'UTF-8').to_a

      ids = boundwith_ids_in_dumpfile +
            missing_constituent_ids_1 +
            missing_constituent_ids_2 +
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

      # QUESTION: Do records from Alma API have the same holdings and item data as
      # from publishing job?
      # 9962645993506421

      # Updated records and records retrieved from the Alma API are cached
      expect(CachedMarcRecord.all.count).to eq 7
    end
  end
end
