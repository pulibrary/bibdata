class ScsbRecallJob < ActiveJob::Base
  include Scsb
  queue_as :scsb_recall

  def perform(message)
    args = parse_scsb_message(message)
    # unless args[:emailAddress].empty?
    #   ScsbMailer.send('recall_email', args).deliver_now
    # end
    ScsbMailer.send('error_email', args).deliver_now if args[:success] == false
  end

end
