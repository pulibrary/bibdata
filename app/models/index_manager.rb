class IndexManager < ActiveRecord::Base
  # @param solr_url Solr URL to get the index manager for (or initialize a new
  #   one)
  # @returns [IndexManager]
  def self.for(solr_url)
    IndexManager.find_or_initialize_by(solr_collection: solr_url)
  end
  belongs_to :dump_in_progress, class_name: "Dump"
  belongs_to :last_dump_completed, class_name: "Dump"

  def index_next_dump!
    return unless next_dump
    self.dump_in_progress = next_dump
    save
    generate_batch do
      next_dump.dump_files.each do |dump_file|
        DumpFileIndexJob.perform_async(dump_file.id, solr_collection)
      end
    end
  end

  def generate_batch
    batch = Sidekiq::Batch.new
    batch.on(:success, IndexManager::Workflow, 'dump_id' => next_dump.id, 'index_manager_id' => id)
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
          recent_full_dump
        end
      end
  end

  def recent_full_dump
    Dump.full_dumps.joins(:event).order("events.start" => "DESC").first
  end

  def next_incremental
    Dump.changed_records.joins(:event).where("events.start > ?", last_dump_completed.event.start.iso8601).order("events.start" => "ASC").first
  end

  class Workflow
    # Callback for when the batch of DumpFiles is done indexing.
    def on_success(_status, options)
      index_manager = IndexManager.find(options['index_manager_id'])
      dump = Dump.find(options['dump_id'])
      index_manager.last_dump_completed = dump
      index_manager.dump_in_progress = nil
      index_manager.save
    end
  end
end
