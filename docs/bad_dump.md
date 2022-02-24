1. `ssh deploy@bibdata-alma-worker1`
1. `cd /opt/marc_liberation/current`
1. `RAILS_ENV=production bundle exec rails c`
1. Find the IndexManager instance that uses the solr production collection. Currenlty is:`catalog-alma-production`
`index_manager_current = IndexManager.all.first`
1. `index_manager_current.solr_collection` => `http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production`
1. Set index_manager_current.last_dump_completed_id to bad dump `index_manager_current.last_dump_completed = <bad_id>`
1. set dump inprogress to nil `index_manager_current.dump_in_progress_id = nil`
1. set inprogress to false `index_manager_current.in_progress = false`
1. save the index manager `index_manager_current.save`
1. Resume index manager `index_manager_current.index_remaining!`
