require 'rails_helper'

RSpec.describe RecapDumpFileProcessingJob do
  describe ".perform" do
    it "processes a dump file, converting all the MARC records for SCSB" do
      dump_file = FactoryBot.create(:recap_incremental_dump_file)
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "alma", "scsb_dump_fixtures", "1.xml.tar.gz"), dump_file.path)

      described_class.perform_now(dump_file)

      # Unzip it, get the MARC-XML
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(dump_file.path))
      tar_extract.tap(&:rewind)
      content = StringIO.new(tar_extract.first.read)
      records = MARC::XMLReader.new(content, external_encoding: 'UTF-8').to_a
      record = records[0]

      # Assertions about the record.
      holding_fields = record.fields("852")
      expect(holding_fields.size).to eq 1
      holding_field = holding_fields.first
      expect(holding_field["b"]).to eq "recap$pa"
      expect(holding_field["c"]).to eq "pa"
      expect(holding_field["0"]).to eq "22107520220006421"
      expect(holding_field["t"]).to be_nil
      expect(holding_field["h"]).to eq "HD1333.B6 S84 1999"
      expect(holding_field["i"]).to be_nil
    end
  end
end
