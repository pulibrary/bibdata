require 'rails_helper'

RSpec.describe Hathi::LoadAccessFile do
  describe ".load" do
    it "idempotently loads the records from the CSV" do
      input_location = Rails.root.join("spec", "fixtures", "files", "overlap_20200429_columbia_abbreviated.tsv")
      loader = described_class.new(input_location: input_location, origin: "CUL")
      loader.load
      expect(HathiAccess.all.count).to eq 14
      loader.load
      expect(HathiAccess.all.count).to eq 14
    end
  end
end
