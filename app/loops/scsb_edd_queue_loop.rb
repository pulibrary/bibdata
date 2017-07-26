class ScsbEddQueueLoop < Loops::Queue
  def process_message(message)
    debug "Received a message: #{message.body}"
    ScsbEddJob.perform_later(message.body)
  end
end
