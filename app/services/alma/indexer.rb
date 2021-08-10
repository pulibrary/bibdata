require 'rubygems/package'
class Alma::Indexer
  attr_reader :solr_url
  def initialize(solr_url:)
    @solr_url = solr_url
  end

  def full_reindex!
    full_reindex_files.each do |dump_file|
      DumpFileIndexJob.perform_async(dump_file.id, solr_url)
    end
  end

  def update_index!
    manager = IndexManager.for(solr_url)
    manager.index_next_dump!
  end

  def incremental_index!(dump)
    raise "received a dump with type other than CHANGED_RECORDS" unless dump.dump_type.constant == "CHANGED_RECORDS"
    dump.update!(index_status: Dump::STARTED)
    dump.dump_files.update(index_status: :started)
    batch = Sidekiq::Batch.new
    batch.on(:success, IncrementalIndexJob, 'dump_id' => dump.id)
    batch.jobs do
      dump.dump_files.each do |dump_file|
        DumpFileIndexJob.perform_async(dump_file.id, solr_url)
      end
    end
  end

  def index_file(file_name, debug_mode = false)
    debug_flag = debug_mode ? "--debug-mode" : ""
    `traject #{debug_flag} -c marc_to_solr/lib/traject_config.rb #{file_name} -u #{solr_url} 2>&1`
  end

  private

    def full_reindex_event
      Event.joins(dump: :dump_type).where(success: true, 'dump_types.constant': "ALL_RECORDS").order(finish: 'DESC').first!
    end

    def full_reindex_files
      full_reindex_event.dump.dump_files.joins(:dump_file_type).where('dump_file_types.constant': 'BIB_RECORDS')
    end

    def full_reindex_file_paths
      full_reindex_files.map(&:path)
    end
end
