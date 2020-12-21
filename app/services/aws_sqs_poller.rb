class AwsSqsPoller
  attr_reader :queue_url
  def initialize(queue_url: nil)
    @queue_url = queue_url || "https://example.com"
  end

  def poll
    poller = Aws::SQS::QueuePoller.new(queue_url)

    poller.poll do |msg|
      dump = AlmaFullDumpFactory.full_bib_dump(msg)
      # running dump creation in the background prevents the queue
      # event from timing out and requeuing
      AlmaFullDumpTransferJob.perform_later(
        dump: dump,
        job_id: msg["job_instance"]["id"],
        type_constant: 'BIB_RECORDS'
      )
    end
  end
end

class AlmaFullDumpFactory
  attr_reader :message
  def initialize(message)
    @message = message
  end

  def self.full_bib_dump(message)
    new(message).full_bib_dump
  end

  def full_bib_dump
    dump = Dump.create(dump_type: DumpType.find_by(constant: 'ALL_RECORDS'))
    dump.event = event
    dump.save
  end

  def dump_event
    @event ||= Event.create(
      start: event_start,
      finish: event_finish,
      succes: true,
      message_body: message.to_json
    )
  end

  def event_start
    message["job_instance"]["start_time"]
  end

  def event_finish
    message["job_instance"]["end_time"]
  end
end
