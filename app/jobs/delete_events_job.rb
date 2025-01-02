class DeleteEventsJob
  include Sidekiq::Worker
  # @param dump_type [Symbol] the dump type of the dumps you want to clean up
  # @param older_than [int] the Time before which dumps should be deleted
  def perform(dump_type, older_than)
    older_than = Time.zone.parse(older_than)
    event_ids = Event.joins(:dump)
                     .where('dump.dump_type': dump_type.to_sym)
                     .where(start: ..older_than)
                     .map(&:id)
    Event.destroy(event_ids)
  rescue ActiveRecord::InvalidForeignKey => e
    Rails.logger.warn("Likely tried to delete a dump that is either the 'dump_in_progress' or 'last_dump_completed' for an index manager.\n Error message: #{e.message}")
  end
end
