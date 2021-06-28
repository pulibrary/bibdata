# encoding: utf-8
require 'zip'
require 'net/sftp'
require 'date'

class Dump < ActiveRecord::Base
  ENQUEUED = 'enqueued'.freeze
  STARTED = 'started'.freeze
  DONE = 'done'.freeze

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

  scope :partner_recap_full, -> { where(dump_type: partner_recap_full_dump_type) }
  scope :partner_recap, -> { where(dump_type: DumpType.where(constant: 'PARTNER_RECAP')) }

  class << self
    ##
    # Create a dump of partner recap incremental records.
    def partner_update
      dump = nil
      timestamp = incremental_update_timestamp
      Event.record do |event|
        dump = Dump.create(dump_type: DumpType.find_by(constant: "PARTNER_RECAP"))
        ScsbImportJob.perform_later(dump.id, timestamp)
        dump.event = event
        dump.save
      end
      dump
    end

    def latest
      order('created_at desc').first
    end

    private

      ##
      # Figure out when was the last time we got partner update records, and find
      # anything that has appeared since then. The ways we can know the last time
      # we got partner update records are:
      # * via an environment variable
      # * look for the last partner recap dump and get its creation date
      # * or, if neither of those, use yesterday
      def incremental_update_timestamp
        (ENV['TIMESTAMP'] || last_incremental_update || DateTime.now - 1).to_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z')
      end

      def last_incremental_update
        Dump.partner_recap.last&.created_at
      end

      def partner_recap_full_dump_type
        dump_type = DumpType.where(constant: 'PARTNER_RECAP_FULL')
      end
  end # class << self

  def enqueued?
    index_status == ENQUEUED
  end

  def started?
    index_status == STARTED
  end

  def done?
    index_status == DONE
  end
end
