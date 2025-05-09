require 'net/sftp'

module Import
  class Alma
    # Downloads the files from the sftp server and attaches them to Event, Dump,
    # DumpFile objects. Kicks off further processing if necessary
    include Sidekiq::Job
    queue_as :default
    attr_reader :dump_file_type

    def perform(dump_id, job_id)
      dump = Dump.find(dump_id)
      @dump_file_type = find_dump_file_type(dump)
      AlmaDownloader.files_for(job_id:, dump_file_type:).each do |file|
        dump.dump_files << file
      end

      dump.save

      IndexManager.for(Rails.application.config.solr['url']).index_remaining! if incremental_dump?
    end

    def incremental_dump?
      dump_file_type == :updated_records
    end

    def find_dump_file_type(dump)
      job_config = find_job_configuration(dump:)
      job_config['dump_file_type'].downcase.to_sym
    end

    class AlmaDownloader
      def self.files_for(job_id:, dump_file_type:)
        new(job_id:, dump_file_type:).files_for
      end

      attr_reader :job_id, :dump_file_type

      def initialize(job_id:, dump_file_type:)
        @job_id = job_id
        @dump_file_type = dump_file_type
      end

      def files_for
        dump_files = []
        Net::SFTP.start(sftp_host, sftp_username, password: sftp_password) do |sftp|
          downloads = []
          remote_paths(sftp_session: sftp).each do |remote_path|
            df = DumpFile.create(dump_file_type:, path: dump_file_path(remote_path))
            dump_files << df
            download = transfer_file(sftp_session: sftp, remote_path:, local_path: df.path)
            downloads << download
          end

          # wait for all asynchronous downloads to complete before closing sftp
          # session
          downloads.each(&:wait)
        end

        dump_files
      end

      # look to sftp server and identify the desired files using job_id
      def remote_paths(sftp_session:)
        sftp_session.dir.entries(remote_base_path).select { |entry| parse_job_id(entry.name) == job_id }.map { |entry| File.join(remote_base_path, entry.name) }
      end

      def remote_base_path
        Rails.configuration.alma['sftp_alma_base_path']
      end

      def dump_file_path(remote_path)
        File.join(MARC_LIBERATION_CONFIG['data_dir'], File.basename(remote_path))
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
        name.split('_')[1]
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
        Rails.configuration.alma['sftp_username']
      end

      def sftp_password
        Rails.configuration.alma['sftp_password']
      end

      def sftp_host
        Rails.configuration.alma['sftp_host']
      end
    end

    private

      def event_message(dump:)
        event = dump.event
        return {} if event.nil?

        JSON.parse(event.message_body)
      end

      def jobs_configuration
        Rails.configuration.alma[:jobs] || {}
      end

      def find_job_configuration(dump:)
        job_name = event_message(dump:).dig('job_instance', 'name')

        jobs_configuration[job_name] || {}
      end
  end
end
