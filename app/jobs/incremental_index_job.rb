class IncrementalIndexJob < ActiveJob::Base
    queue_as :default

    def perform(dump)
    end
end
  