class ScsbRequestJob < ActiveJob::Base
  include Scsb
  queue_as :scsb_request

  def perform(message)
    args = parse_scsb_message(message)
    # unless args[:emailAddress].blank?
    #   ScsbMailer.send('request_email', args).deliver_now
    # end
    if args[:success] == false
      ScsbMailer.send('error_email', args).deliver_now
    end
  end
end
