require 'net/sftp'

class AlmaFullDumpTransferJob < ActiveJob::Base
  queue_as :default

  REMOTE_BASE_PATH = "/home/alma".freeze

  def perform(dump:, job_id:, type_constant: 'BIB_RECORDS')
    dump_file_type = DumpFileType.find_by(constant: type_constant)
    Net::SFTP.start(sftp_host, sftp_username, password: sftp_password) do |sftp|
      downloads = []
      remote_paths(job_id: job_id, sftp_session: sftp).each do |path|
        df = DumpFile.create(dump_file_type: dump_file_type)
        download = transfer_file(sftp_session: sftp, remote_path: path, local_path: df.path)
        dump.dump_files << df
        downloads << download
      end
      dump.save
      # wait for all asynchronous downloads to complete before closing sftp
      # session
      downloads.each(&:wait)
    end
  end

  private

    # look to sftp server and identify the desired files using job_id
    def remote_paths(job_id:, sftp_session:)
      sftp_session.dir.entries(REMOTE_BASE_PATH).select { |entry| parse_job_id(entry.name) == job_id }.map { |entry| File.join(REMOTE_BASE_PATH, entry.name) }
    end

    # By default alma puts the timestamp before the job_id in filenames, and the
    #   default timestamp used differed from the documented timestamp
    #
    # So we configured the job_id to come before the timestamp to
    # protect against future variation in the timestamp format.
    # configured form is:
    # fulldump_<job ID>_<time stamp>_<new or update or delete>_<counter>.xml.tar.gz
    #
    # documentation is at
    # https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_(English)/090Integrations_with_External_Systems/030Resource_Management/080Publishing_and_Inventory_Enrichment#File_name
    def parse_job_id(name)
      name.split("_")[1]
    end

    # Do the actual download from the sftp server
    def transfer_file(sftp_session:, remote_path:, local_path:)
      File.truncate(local_path, 0) if File.exist?(local_path)
      sftp_session.download(remote_path, local_path)
    end

    def sftp_options
      {
        username: sftp_username,
        password: sftp_password,
        passive: true,
        ssl: true
      }
    end

    def sftp_username
      Rails.configuration.alma["sftp_username"]
    end

    def sftp_password
      Rails.configuration.alma["sftp_password"]
    end

    def sftp_host
      Rails.configuration.alma["sftp_host"]
    end
end
