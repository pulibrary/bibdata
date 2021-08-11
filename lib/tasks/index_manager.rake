namespace :index_manager do
  desc "Initialize index manager for the current production Solr URL with the latest dump"
  task initialize: :environment do
    solr_url = Rails.application.config.solr["url"]
    most_recent_dump = Dump.changed_records.joins(:events).order('events.started' => 'DESC').first
    manager = IndexManager.for(solr_url)
    manager.last_dump_completed = most_recent_dump
    manager.save!
    puts "Created IndexManager for #{solr_url} pointed to Dump ID #{solr_url}"
  end
end
