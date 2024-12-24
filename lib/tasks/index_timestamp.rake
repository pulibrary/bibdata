namespace :index_timestamp do
  desc 'Check the timestamp for the last index update and raise an error if it has not updated today'
  task check: :environment do
    active_manager = IndexManager.all.select { |index_manager| index_manager.solr_collection.match(/catalog-alma-production$/) }
    if (Time.zone.now - active_manager.updated_at).to_i > 86_400
      Honeybadger.notify('The index has not been updated in more than 24 hours. Please check if the incremental updates are running.')
    end
  end
end
