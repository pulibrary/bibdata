# encoding: utf-8
require 'zip'
require 'net/sftp'
require 'date'
require_relative './concerns/scsb_partner_updates'

class Dump < ActiveRecord::Base
  belongs_to :event
  belongs_to :dump_type
  has_many :dump_files
  # These only apply to change dumps (stored in db rather than text files)
  serialize :delete_ids
  serialize :update_ids
  serialize :recap_barcodes

  before_destroy do
    self.dump_files.each do |df|
      df.destroy
    end
  end

  def dump_updated_recap_records(updated_barcodes)
    dump_file_type = DumpFileType.find_by(constant: 'RECAP_RECORDS')
    dump_records(updated_barcodes, dump_file_type)
  end

  private

    def dump_records(ids, dump_file_type, priority = 'default')
      slice_size = if Rails.env.test?
                     MARC_LIBERATION_CONFIG['test_records_per_file']
                   elsif dump_file_type.constant == 'RECAP_RECORDS'
                     MARC_LIBERATION_CONFIG['recap_dump_records_per_file']
                   else
                     MARC_LIBERATION_CONFIG['records_per_file']
                   end

      ids.each_slice(slice_size).each do |id_slice|
        df = DumpFile.create(dump_file_type: dump_file_type)
        self.dump_files << df
        self.save
        if dump_file_type.constant == 'RECAP_RECORDS'
          RecapDumpJob.perform_later(id_slice, df.id)
        else
          BibDumpJob.set(queue: priority).perform_later(id_slice, df.id)
        end
        sleep 1
      end
    end

    class << self
      def dump_recap_records
        dump_ids('PRINCETON_RECAP')
      end

      def partner_update
        dump = nil
        dump_type = 'PARTNER_RECAP'
        timestamp = incremental_update_timestamp(dump_type)
        Event.record do |event|
          dump = Dump.create(dump_type: DumpType.find_by(constant: dump_type))
          ScsbImportJob.perform_later(dump.id, timestamp)
          dump.event = event
          dump.save
        end
        dump
      end

      private

        def last_bib_id_dump
          dump_type = DumpType.where(constant: 'BIB_IDS')
          dump = Dump.where(dump_type: dump_type).joins(:event).where('events.success' => true).order('id desc').first
        end

        def last_recap_dump
          dump_type = DumpType.where(constant: 'PRINCETON_RECAP')
          dump = Dump.where(dump_type: dump_type).joins(:event).where('events.success' => true).order('id desc').first
        end

        def incremental_update_timestamp(dump_type)
          (ENV['TIMESTAMP'] || last_incremental_update(dump_type) || DateTime.now - 1).to_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z')
        end

        def last_incremental_update(dump_type)
          last_dump = Dump.where(dump_type: DumpType.find_by(constant: dump_type)).last
          last_dump = last_recap_dump if dump_type == "PRINCETON_RECAP"
          last_dump&.created_at
        end

        def dump_ids(type)
          # TODO: Re-enable. Disabled as we no longer have VoyagerHelpers.
          # dump = nil
          # Event.record do |event|
          #   dump = Dump.create(dump_type: DumpType.find_by(constant: type))
          #   dump.event = event
          #   dump_file = DumpFile.create(dump: dump, dump_file_type: DumpFileType.find_by(constant: type)) unless type == 'PRINCETON_RECAP'
          #   if type == 'BIB_IDS'
          #     VoyagerHelpers::SyncFu.bib_ids_to_file(dump_file.path)
          #   elsif type == 'PRINCETON_RECAP'
          #     timestamp = incremental_update_timestamp(type).to_time
          #     barcodes = VoyagerHelpers::SyncFu.recap_barcodes_since(timestamp)
          #     dump.update_ids = barcodes
          #     dump.save
          #     dump.dump_updated_recap_records(barcodes)
          #   else
          #     raise 'Unrecognized DumpType'
          #   end
          #   unless type == 'PRINCETON_RECAP'
          #     dump_file.save
          #     dump_file.zip
          #     dump.dump_files << dump_file
          #   end
          #   dump.save
          # end
          # dump
        end
    end # class << self
end
