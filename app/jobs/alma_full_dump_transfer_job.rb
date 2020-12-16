class AlmaFullDumpTransferJob < ActiveJob::Base
  queue_as :default

  def perform(dump:, start:, finish:, type_constant:)
    dump_file_type = DumpFileType.find_by(constant: type_constant)
    remote_paths(start, finish).each do |path|
      df = DumpFile.create(dump_file_type: dump_file_type)
      transfer_file(remote_path: path, local_path: df.path)
      df.zip
      df.save
      dump.dump_files << df
      dump.save
    end

    # look to ftp server and identify the desired files using times
    #  and known filenames
    def remote_paths(start, finish)
    end

    # Do the actual download from the ftp server
    def transfer_file(remote_path:, local_path:)
      # File.truncate(local_path, 0) if File.exist?(local_path)
    end
  end
end
