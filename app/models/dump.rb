# encoding: utf-8
require 'zip'
require 'net/sftp'
require 'date'

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

  class << self
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

      def last_recap_dump
        dump_type = DumpType.where(constant: 'PRINCETON_RECAP')
        Dump.where(dump_type: dump_type).joins(:event).where('events.success' => true).order('id desc').first
      end

      def incremental_update_timestamp(dump_type)
        (ENV['TIMESTAMP'] || last_incremental_update(dump_type) || DateTime.now - 1).to_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z')
      end

      def last_incremental_update(dump_type)
        last_dump = Dump.where(dump_type: DumpType.find_by(constant: dump_type)).last
        last_dump = last_recap_dump if dump_type == "PRINCETON_RECAP"
        last_dump&.created_at
      end
  end # class << self
end
