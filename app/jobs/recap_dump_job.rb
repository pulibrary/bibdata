require 'voyager_helpers'
require 'net/sftp'

class RecapDumpJob < ActiveJob::Base
  queue_as :default

  def perform(barcode_slice, df_id)
    df = DumpFile.find(df_id)
    File.truncate(df.path, 0) if File.exist?(df.path)
    # true is passed to make sure this returns recap flavored data
    VoyagerHelpers::Liberator.dump_merged_records_to_file(barcode_slice, df.path, true)
    df.zip
    df.save
    transfer_recap_dump_file(df)
  end

  def transfer_recap_dump_file(dump_file)
    Net::SSH.start(ENV['RECAP_SERVER'], ENV['RECAP_UPDATE_USER'], { port: 2222, keys: [ENV['RECAP_TRANSFER_KEY']] } ) do |ssh|
      ssh.sftp.upload!(dump_file.path, "#{ENV['RECAP_UPDATE_DIR']}/#{File.basename(dump_file.path)}")
    end
  end
end
