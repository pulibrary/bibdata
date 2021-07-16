class DeleteEventsJob < ActiveJob::Base
  # @param dump_type [String] the dump type of the dumps you want to clean up
  # @param older_than [int] the Time before which dumps should be deleted, serialized as an integer
  def perform(dump_type:, older_than:)
    start = Event.arel_table[:start]
    ids = Event
          .joins(dump: :dump_type)
          .where('dump_types.constant': dump_type)
          .where(start.lt(deserialize_time(older_than)))
          .map(&:id)

    Event.destroy(ids)
  end

  def deserialize_time(time)
    Time.zone.at(time)
  end
end
