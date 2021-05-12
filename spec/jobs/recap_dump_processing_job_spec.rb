require 'rails_helper'

RSpec.describe RecapDumpProcessingJob do
  describe ".perform" do
    it "enqueues a RecapDumpFileProcessingJob for each DumpFile" do
      dump = FactoryBot.create(:recap_incremental_dump)

      described_class.perform_now(dump)
      expect(RecapDumpFileProcessingJob).to have_been_enqueued.twice
      expect(RecapBoundwithsProcessingJob).to have_been_enqueued
    end
  end
end
