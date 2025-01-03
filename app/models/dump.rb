require 'zip'
require 'net/sftp'
require 'date'

class Dump < ActiveRecord::Base
  ENQUEUED = 'enqueued'.freeze
  STARTED = 'started'.freeze
  DONE = 'done'.freeze

  belongs_to :event
  has_many :dump_files
  # These only apply to change dumps (stored in db rather than text files)
  serialize :delete_ids
  serialize :update_ids
  serialize :recap_barcodes
  validates :event_id, presence: true

  before_destroy do
    self.dump_files.each do |df|
      df.destroy
    end
  end

  enum dump_type: {
    full_dump: 1,
    changed_records: 2,
    princeton_recap: 3,
    partner_recap: 4,
    partner_recap_full: 5,
    bib_ids: 6,
    merged_ids: 7
  }

  class << self
    ##
    # Create a dump of partner recap incremental records.
    def partner_update
      dump = nil
      timestamp = incremental_update_timestamp.to_s
      Event.record do |event|
        event.save
        dump = Dump.create(dump_type: :partner_recap, event_id: event.id)
        Import::Partner::Incremental.perform_async(dump.id, timestamp)
        dump.save
      end
      dump
    end

    def latest_generated
      order('generated_date desc').first
    end

    def generated_date(dump_id)
      dump = Dump.find(dump_id)
      dump.generated_date = dump.date_strings.map { |str| DateTime.parse(str) }.min
      dump.save!
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
        (ENV.fetch('TIMESTAMP', nil) || last_incremental_update || (DateTime.now - 1)).to_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z')
      end

      def last_incremental_update
        Dump.partner_recap.last&.created_at
      end
  end # class << self

  def date_strings
    dump_files.map do |df|
      if df.dump_file_type == 'recap_records_full_metadata'
        File.basename(df.path).split('_')[3]
      else
        File.basename(df.path).split('_')[2]
      end
    end
  end

  def subsequent_partner_incrementals
    Dump.partner_recap.where(generated_date: generated_date..Float::INFINITY)
  end

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
