require 'rails_helper'

RSpec.describe RecapDumpFileProcessingJob do
  before do
    allow(RecapTransferService).to receive(:transfer).and_return(true)
  end

  describe ".perform" do
    let(:dump_file) { FactoryBot.create(:recap_incremental_dump_file) }
    let(:fixture_file) { "recap_6836725000006421_20210401_010420[012]_new_1.xml.tar.gz" }

    before do
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "alma", "scsb_dump_fixtures", fixture_file), dump_file.path)
    end

    after do
      FileUtils.rm_rf Dir.glob("#{MARC_LIBERATION_CONFIG['data_dir']}/*")
    end

    it "processes a dump file, converting all the MARC records for SCSB" do
      output_file_path = described_class.perform_now(dump_file)

      # Unzip it, get the MARC-XML
      records = dump_file_to_marc(path: output_file_path)
      record = records[0]

      # Requirements documentation:
      # https://htcrecap.atlassian.net/wiki/spaces/RTG/pages/27692276/Ongoing+Accession+Submit+Collection+through+API
      # Assertions about the record.
      holding_fields = record.fields("852")
      expect(holding_fields.size).to eq 1
      holding_field = holding_fields.first
      expect(holding_field["b"]).to eq "recap$pa"
      expect(holding_field["0"]).to eq "22107520220006421"
      expect(holding_field["h"]).to eq "HD1333.B6 S84 1999"

      # Ensure there are no non-numeric fields
      # ReCAP's parser can't handle them.
      expect(record.fields.map { |x| format("%03d", x.tag.to_i) }).to contain_exactly(*record.fields.map(&:tag))

      # 876 (item) tests
      expect(record["876"]["0"]).to eq "22107520220006421"
      expect(record["876"]["a"]).to eq "23107520210006421"
      expect(record["876"]["p"]).to eq "32101082696012"
      expect(record["876"]["x"]).to eq "Shared"
      expect(record["876"]["z"]).to eq "PA"
      expect(record["876"]["j"]).to eq "Not Used"
      expect(record["876"]["l"]).to eq "RECAP"
      expect(record["876"]["k"]).to eq "recap"

      expect(record.leader).to eq "01334cam a2200361 a 4500"

      # File is transferred to S3
      expect(RecapTransferService).to have_received(:transfer)
    end

    context "with a dumpfile that contains boundwiths" do
      let(:fixture_file) { "boundwiths.tar.gz" }

      it "does not process boundwith records" do
        output_file_path = described_class.perform_now(dump_file)

        # Unzip it, get the MARC-XML
        records = dump_file_to_marc(path: output_file_path)
        expect(records.count).to eq 1
      end
    end

    context "when there is a problem uploading a file to s3" do
      before do
        allow(RecapTransferService).to receive(:transfer).and_return(false)
      end

      it "raises an error" do
        expect { described_class.perform_now(dump_file) }.to raise_error(StandardError, /Error uploading file/)
      end
    end
  end
end
