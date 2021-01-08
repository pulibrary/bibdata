namespace :marc_liberation do
  namespace :indexing do
    desc "Start the sqs poller -- for use by system daemon"
    task :poll_sqs do
      AwsSqsPoller.poll
    end
  end
end
