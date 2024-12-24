namespace :index_manager do
  desc 'Initialize index manager for the current production Solr URL with the latest dump'
  task initialize: :environment do
    solr_url = Rails.application.config.solr['url']
    most_recent_dump = Dump.changed_records.joins(:events).order('events.started' => 'DESC').first
    manager = IndexManager.for(solr_url)
    manager.last_dump_completed = most_recent_dump
    manager.save!
    puts "Created IndexManager for #{solr_url} pointed to Dump ID #{solr_url}"
  end

  desc 'Swap rebuild index manager for production index manager. Do this RIGHT BEFORE swapping the alias for a rebuild.'
  task promote_rebuild_manager: :environment do
    old_prod_manager = IndexManager.for(Rails.application.config.solr['url'])
    prod_alias = old_prod_manager.solr_collection
    new_prod_manager = IndexManager.for("#{Rails.application.config.solr['url']}-rebuild")
    rebuild_alias = new_prod_manager.solr_collection
    old_prod_manager.solr_collection = 'temp'
    old_prod_manager.save
    new_prod_manager.solr_collection = prod_alias
    new_prod_manager.save
    old_prod_manager.solr_collection = rebuild_alias
    old_prod_manager.save
    puts 'Swapped rebuild index manager with production index manager.'
  end
end
