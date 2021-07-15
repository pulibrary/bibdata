require 'rails_helper'

RSpec.describe DumpFileIndexJob do
  describe "#perform" do
    it "raises an error when traject errors" do
      dump = FactoryBot.create(:incremental_dump)

      expect { described_class.new.perform(dump.dump_files.first.id, "http://localhost:8983/solr/badcollection") }.to raise_error
    end
  end
end
