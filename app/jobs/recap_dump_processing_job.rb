# Process recap files from alma into files for SCSB
class RecapDumpProcessingJob < ActiveJob::Base
  def perform(dump)
    RecapBoundwithsProcessingJob.perform_later(dump)

    dump.dump_files.each do |dump_file|
      # Dump files must be processed serially for performance
      # reasons on production infrastructure.
      RecapDumpFileProcessingJob.perform_now(dump_file)
    end
  end
end
