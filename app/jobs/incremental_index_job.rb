class IncrementalIndexJob < ActiveJob::Base
  class IndexQueueLocked < StandardError; end

  queue_as :default
  retry_on IndexQueueLocked

  def perform(dump)
    dump.index_status = Dump::ENQUEUED
    dump.save!

    raise IndexQueueLocked unless running_jobs.empty?

    dump.index_status = Dump::STARTED
    dump.save!

    indexer.incremental_index!(dump)

    dump.index_status = Dump::DONE
    dump.save!
  rescue StandardError => indexer_error
    Rails.logger.error("Failed to incrementally index Dump #{dump.id}: indexer_error")
    raise(indexer_error)
  end

  private

    def solr_config
      Rails.application.config.solr
    end

    def indexer
      @indexer ||= Alma::Indexer.new(solr_url: solr_config['url'])
    end

    def current_time
      DateTime.now
    end

    def running_jobs
      @running_jobs ||= Dump.all.select { |d| d.started? && d.updated_at <= current_time }
    end
end
