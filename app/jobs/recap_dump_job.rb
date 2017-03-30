require 'voyager_helpers'

class RecapDumpJob < ActiveJob::Base
  queue_as :default
 
  def perform(barcode_slice, df_id)
    df = DumpFile.find(df_id)
    File.truncate(df.path, 0) if File.exist?(df.path)
    VoyagerHelpers::Liberator.dump_merged_records_to_file(barcode_slice, df.path)
    df.zip
    df.save
  end
end

