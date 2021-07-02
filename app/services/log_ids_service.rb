# Process a MARC file and logs the IDs deleted and updated in the file
class LogIdsService
  def process_file(file)
    indexer = Traject::Indexer.new
    indexer.load_config_file(config_file)
    indexer.process(file)
  end

  # Note: Our MARC files have 100K records so theorically the maximum number of
  # deleted_ids or updated_ids will be that.
  def self.save(delete_ids:, update_ids:)
    # Create an event...
    ev = Event.new(start: Time.now, finish: Time.now, success: true)
    ev.save

    # ...and record the deleted and updated IDs
    dump_type_id = DumpType.where(constant: "CHANGED_RECORDS").first.id
    dump = Dump.new(dump_type_id: dump_type_id, event_id: ev.id)
    dump.delete_ids = delete_ids
    dump.update_ids = update_ids
    dump.save
  end

  private

    def config_file
      Rails.root.join('marc_to_solr', 'lib', 'traject_log_ids_config.rb').to_s
    end
end
