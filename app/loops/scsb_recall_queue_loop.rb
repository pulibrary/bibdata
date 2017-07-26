class ScsbRecallQueueLoop < Loops::Queue
  def process_message(message)
    debug "Received a message: #{message.body}"
    ScsbRecallJob.perform_later(message.body)
  end
end
