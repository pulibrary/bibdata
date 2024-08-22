# What to do when dump file fails to index
1. `ssh deploy@bibdata-worker-prod1`
1. `cd /opt/bibdata/current`
1. `RAILS_ENV=production bundle exec rails c`
1. Find the IndexManager instance that uses the solr production collection. Currently the name of the solr catalog production collection is:`catalog-alma-production`.  
`index_manager_current = IndexManager.where(solr_collection: "http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production").first`
1. Set `last_dump_completed_id` to bad dump: `index_manager_current.last_dump_completed_id = <bad_id>`
   <bad_id> is usually `index_manager_current.dump_in_progress_id`
1. Set `dump_in_progress_id` to nil: `index_manager_current.dump_in_progress_id = nil`
1. Set `in_progress` to false: `index_manager_current.in_progress = false`
1. Save the index manager: `index_manager_current.save!`
1. Resume index manager: `index_manager_current.index_remaining!`
