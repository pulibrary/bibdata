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

  def incremental_index!(dump)
    dump.dump_files.each do |dump_file|
      DumpFileIndexJob.perform_async(dump_file.id, solr_url)
    end
  end

  def index_file(file_name, debug_mode = false)
    debug_flag = debug_mode ? "--debug-mode" : ""
    `traject #{debug_flag} -c marc_to_solr/lib/traject_config.rb #{file_name} -u #{solr_url}; true`
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
