module Import
  module Partner
    class FullCallbacks
      def overall_success(_status, options)
        event = Event.find(options['event_id'])
        Dump.generated_date(event.dump.id)
        event.success = true
        event.finish = Time.now.utc
        event.save!
      end

      def validate_csv_success(status, options)
        institution = options['institution']
        dump_id = options['dump_id']
        prefix = options['prefix']
        dump = Dump.find(dump_id)

        overall = Sidekiq::Batch.new(status.parent_bid)
        overall.jobs do
          download_full_file_batch = Sidekiq::Batch.new
          download_full_file_batch.description = "Download full dump for institution #{institution}"
          download_full_file_batch.on(:success, 'Import::Partner::FullCallbacks#download_file_success', 'dump_id' => dump_id, 'institution' => institution, 'prefix' => prefix)
          download_full_file_batch.jobs do
            Import::Partner::DownloadFullFileJob.perform_async(dump_id, institution, prefix)
          end
        end
      end

      # Empty callbacks in preparation for future further breaking down of background jobs
      def download_file_success(status, options); end

      def process_xml_file_success(_status, options)
        # unlink big zip file here
        zip_file = options['zip_file']
        # rubocop:disable Lint/NonAtomicFileOperation
        File.unlink(zip_file) if File.exist?(zip_file)
        # rubocop:enable Lint/NonAtomicFileOperation
      end
    end
  end
end
