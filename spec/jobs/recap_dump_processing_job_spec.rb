require 'rails_helper'

RSpec.describe RecapDumpProcessingJob do
  describe ".perform" do
    before do
      allow(RecapDumpFileProcessingJob).to receive(:perform_now)
    end

    it "enqueues a RecapDumpFileProcessingJob for each DumpFile" do
      dump = FactoryBot.create(:recap_incremental_dump)

      described_class.perform_now(dump)
      expect(RecapDumpFileProcessingJob).to have_received(:perform_now).twice
      expect(RecapBoundwithsProcessingJob).to have_been_enqueued
    end
  end
end
