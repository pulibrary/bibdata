class IndexManager < ActiveRecord::Base
  # @param solr_url Solr URL to get the index manager for (or initialize a new
  #   one)
  # @returns [IndexManager]
  def self.for(solr_url)
    IndexManager.find_or_initialize_by(solr_collection: solr_url)
  end

  def self.reindex!(solr_url: nil)
    solr_url ||= rebuild_solr_url
    manager = self.for(solr_url)
    return if manager.in_progress?
    manager.last_dump_completed = nil
    manager.save
    manager.wipe!
    manager.index_remaining!
  end

  def self.rebuild_solr_url
    "#{Rails.application.config.solr['url']}-rebuild"
  end

  belongs_to :dump_in_progress, class_name: "Dump"
  belongs_to :last_dump_completed, class_name: "Dump"

  def wipe!
    RSolr.connect(url: solr_collection).delete_by_query("*:*")
  end

  def index_next_dump!
    return unless next_dump
    self.dump_in_progress = next_dump
    self.in_progress = true
    save
    generate_batch do
      next_dump.dump_files.each do |dump_file|
        DumpFileIndexJob.perform_async(dump_file.id, solr_collection)
      end
    end
  end

  def index_remaining!
    # Don't do anything unless there's a job to index and we're not already
    # indexing.
    return unless next_dump && !in_progress?
    save!
    # Create an overall catchup batch.
    batch = Sidekiq::Batch.new
    batch.on(:success, "IndexManager::Workflow#indexed_remaining", 'index_manager_id' => id)
    batch.description = "Performing catch-up index into #{solr_collection}"
    batch.jobs do
      IndexRemainingDumpsJob.perform_async(id)
    end
  end

  def generate_batch
    batch = Sidekiq::Batch.new
    batch.on(:success, IndexManager::Workflow, 'dump_id' => next_dump.id, 'index_manager_id' => id)
    batch.description = "Indexing Dump #{next_dump.id} into #{solr_collection}"
    batch.jobs do
      yield
    end
  end

  def next_dump
    @next_dump ||=
      begin
        if last_dump_completed
          next_incremental
        else
          recent_full_dump || first_incremental
        end
      end
  end

  def recent_full_dump
    Dump.full_dumps.joins(:event).order("events.start" => "DESC").first
  end

  def first_incremental
    Dump.changed_records.joins(:event).order("events.start" => "ASC").first
  end

  def next_incremental
    Dump.changed_records.joins(:event).where("events.start": last_dump_completed.event.start..Float::INFINITY).where.not(id: last_dump_completed.id).order("events.start" => "ASC").first
  end

  class Workflow
    # Callback for when the batch of DumpFiles is done indexing.
    def on_success(status, options)
      index_manager = IndexManager.find(options['index_manager_id'])
      dump = Dump.find(options['dump_id'])
      index_manager.last_dump_completed = dump
      index_manager.dump_in_progress = nil
      index_manager.save
      # If there's a parent batch it's meant to keep going until it runs out of
      # dumps.
      if status.parent_bid
        return unless index_manager.next_dump
        overall = Sidekiq::Batch.new(status.parent_bid)
        overall.jobs do
          index_manager.index_next_dump!
        end
      else
        index_manager.in_progress = false
        index_manager.save
      end
    end

    def indexed_remaining(_status, options)
      index_manager = IndexManager.find(options['index_manager_id'])
      index_manager.dump_in_progress = nil
      index_manager.in_progress = false
      index_manager.save
    end
  end
end
