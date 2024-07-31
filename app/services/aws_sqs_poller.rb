# This service is intended to be run by a daemon. It watches the AWS SQS poll
# for full dump events and kicks off a job to process them.
class AwsSqsPoller
  def self.poll
    queue_url = Rails.configuration.alma["sqs_queue_url"]
    poller = Aws::SQS::QueuePoller.new(queue_url)
    end_polling = false

    # End polling if the process is killed by restarting.
    Signal.trap("TERM") do
      end_polling = true
    end

    poller.before_request do |_stats|
      throw :stop_polling if end_polling
    end

    poller.poll do |msg|
      message_body = JSON.parse(msg[:body])
      job_name = message_body["job_instance"]["name"]
      next unless Rails.configuration.alma[:jobs].keys.include?(job_name)
      dump = AlmaDumpFactory.bib_dump(message_body)
      # running dump creation in the background prevents the queue
      # event from timing out and requeuing
      AlmaDumpTransferJob.perform_later(
        dump:,
        job_id: message_body["job_instance"]["id"]
      )
    end
  end
end

class AlmaDumpFactory
  attr_reader :message
  def initialize(message)
    @message = message
  end

  def self.bib_dump(message)
    new(message).bib_dump
  end

  def bib_dump
    Dump.create(dump_type:,
                event: dump_event,
                generated_date: dump_event.start)
  end

  def dump_type
    @dump_type ||= Rails.configuration.alma[:jobs][job_name]["dump_type"]
  end

  def job_name
    message["job_instance"]["name"]
  end

  def alma_job_status
    message["job_instance"]["status"]["value"]
  end

  def dump_event
    @event ||= Event.create!(
      start: event_start,
      finish: event_finish,
      success: true,
      alma_job_status:,
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
