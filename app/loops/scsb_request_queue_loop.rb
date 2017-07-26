class ScsbRequestQueueLoop < Loops::Queue
  def process_message(message)
    debug "Received a message: #{message.body}"
    ScsbRequestJob.perform_later(message.body)
  end
end
