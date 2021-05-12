# Process recap dump files and create recap boundwiths dumpfile
class RecapDumpProcessingJob < ActiveJob::Base
  def perform(dump)
    dump.dump_files.each do |dump_file|
      RecapDumpFileProcessingJob.perform_later(dump_file)
    end

    RecapBoundwithsProcessingJob.perform_later(dump)
  end
end
