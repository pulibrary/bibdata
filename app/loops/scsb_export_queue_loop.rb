class ScsbExportQueueLoop < Loops::Queue
  def process_message(message)
    debug "Received a message: #{message.body}"
    ScsbExportJob.perform_later(message.body)
  end
end
