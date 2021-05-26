require 'rails_helper'

RSpec.describe AlmaAdapter::ScsbDumpRecord do
  let(:host_record) do
    file = file_fixture("alma/scsb_dump_fixtures/host.xml").to_s
    MARC::XMLReader.new(file, external_encoding: 'UTF-8').first
  end

  let(:bad_host_record) do
    file = file_fixture("alma/scsb_dump_fixtures/bad-host.xml").to_s
    MARC::XMLReader.new(file, external_encoding: 'UTF-8').first
  end

  let(:host_record_uncached) do
    file = file_fixture("alma/scsb_dump_fixtures/host-id-not-in-cache.xml").to_s
    MARC::XMLReader.new(file, external_encoding: 'UTF-8').first
  end

  let(:constituent_record) do
    file = file_fixture("alma/scsb_dump_fixtures/constituent.xml").to_s
    MARC::XMLReader.new(file, external_encoding: 'UTF-8').first
  end

  let(:bad_constituent_record) do
    file = file_fixture("alma/scsb_dump_fixtures/bad-constituent.xml").to_s
    MARC::XMLReader.new(file, external_encoding: 'UTF-8').first
  end

  let(:non_boundwith_record) do
    file = file_fixture("alma/scsb_dump_fixtures/notboundwith.xml").to_s
    MARC::XMLReader.new(file, external_encoding: 'UTF-8').first
  end

  it "is a MARC Record" do
    expect(host_record).to be_a MARC::Record
    expect(constituent_record).to be_a MARC::Record
  end

  describe "#boundwith?" do
    context "with a host record" do
      it "returns true" do
        expect(described_class.new(marc_record: host_record).boundwith?).to be true
      end
    end

    context "with a constituent record" do
      it "returns true" do
        expect(described_class.new(marc_record: constituent_record).boundwith?).to be true
      end
    end

    context "with a non-boundwith record" do
      it "returns false" do
        expect(described_class.new(marc_record: non_boundwith_record).boundwith?).to be false
      end
    end
  end

  describe "#constituent?" do
    context "with a host record" do
      it "returns false" do
        expect(described_class.new(marc_record: host_record).constituent?).to be false
      end
    end

    context "with a constituent record" do
      it "returns true" do
        expect(described_class.new(marc_record: constituent_record).constituent?).to be true
      end
    end

    context "with a malformed constituent record" do
      it "returns false" do
        expect(described_class.new(marc_record: bad_constituent_record).constituent?).to be false
      end
    end
  end

  describe "#host?" do
    context "with a host record" do
      it "returns true" do
        expect(described_class.new(marc_record: host_record).host?).to be true
      end
    end

    context "with a malformed host record" do
      it "returns false" do
        expect(described_class.new(marc_record: bad_host_record).host?).to be false
      end
    end

    context "with a constituent record" do
      it "returns false" do
        expect(described_class.new(marc_record: constituent_record).host?).to be false
      end
    end
  end

  describe "#cache" do
    it "caches a record in the database" do
      described_class.new(marc_record: host_record).cache

      record = CachedMarcRecord.find_by(bib_id: "99121886293506421")
      expect(record.bib_id).to eq "99121886293506421"
      expect(record.marc).to include("<subfield code")
    end
  end

  context "with methods that make use of cached marc records" do
    before do
      PublishingJobFileService.new(path: "spec/fixtures/files/alma/scsb_dump_fixtures/cacheable_scsb_records.tar.gz").cache
    end

    describe "#host_record" do
      it "retrieves a host record from the cache" do
        record = described_class.new(marc_record: constituent_record).host_record
        expect(record.id).to eq "99116515383506421"
      end
    end

    describe "#constituent_record" do
      context "with no skipped records" do
        let(:missing_constituent_ids) { ["9929455783506421", "9929455793506421", "9929455773506421"] }

        it "retrieves all constituent records from the cache" do
          records = described_class.new(marc_record: host_record).constituent_records
          expect(records.map { |r| r.marc_record["001"].value }).to contain_exactly(*missing_constituent_ids)
        end
      end

      context "with skipped records" do
        let(:missing_constituent_ids) { ["9929455783506421", "9929455793506421"] }

        it "retrieves non-skipped constituent records from the cache" do
          records = described_class.new(marc_record: host_record).constituent_records(skip_ids: ["9929455773506421"])
          expect(records.map { |r| r.marc_record["001"].value }).to contain_exactly(*missing_constituent_ids)
        end
      end
    end

    context "with records missing from the cache" do
      it "raises an exception" do
        expect { described_class.new(marc_record: host_record_uncached).constituent_records }.to raise_error(AlmaAdapter::ScsbDumpRecord::CacheMiss, "9929455783506421,9998765433506421,9912345673506421")
      end
    end
  end
end
