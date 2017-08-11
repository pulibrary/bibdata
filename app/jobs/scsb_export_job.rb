class ScsbExportJob < ActiveJob::Base
  include Scsb
  queue_as :scsb_export

  def perform(message)
    args = parse_scsb_message(message)
    ApplicationMailer.send('export_email', args).deliver_now
  end
end
