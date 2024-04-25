class DeleteEventsJob < ApplicationJob
  # @param dump_type [Symbol] the dump type of the dumps you want to clean up
  # @param older_than [int] the Time before which dumps should be deleted
  def perform(dump_type:, older_than:)
    event_ids = Event.joins(:dump)
                     .where('dump.dump_type': dump_type)
                     .where(start: ..older_than)
                     .map(&:id)
    Event.destroy(event_ids)
  end
end
