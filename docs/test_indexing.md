# Scenario 1: Test indexing a specific .xml file

1. Create a publishing file in Alma (Either in the sandbox or production)
    1. Create a Query that contains the data you would like to query.  Save the query after you have it correct
    1. Change the "DACS Test Record Export" publishing job (under Resources) to point at your saved query
       Resources -> Publishing Profiles, Edit the DRDS test records publishing job to point to the new data set.
    1. Run the "DACS Test Record Export" publishing job by clicking run under the "..." menu after the save
    1. Wait for the job to complete successfully.
1. Download the file from the Alma SFTP.  If you ran the job from the Alma sandbox look in the /alma/sandbox directory otherwise the file should be created at the /alma directory.
1. Unzip and rename the file to something that makes sense to you locally `<file name>.xml`
1. sftp the file up to the staging worker machine
   `scp <local file> deploy@bibdata-alma-worker-staging1:`
1. deploy the code you would like to test to the staging server you sftped the file up to 
1. ssh onto the place that you ftped the file to and go to the current deployment directory
   ```
   ssh deploy@bibdata-alma-worker-staging1
   cd /opt/bibdata/current
   ``` 
1. run `SET_URL=http://lib-solr8-staging.princeton.edu:8983/solr/catalog-staging FILE=/home/deploy/<file name>.xml RAILS_ENV=production bundle exec rake liberate:index_file`

# Scenario 2: Test indexing by triggering an incremental dump.

Follow: https://github.com/pulibrary/bibdata/blob/main/docs/alma.md#trigger-an-incremental-job-in-the-alma-sandbox

# Scenario 3: Test indexing an existing dump file with dump type 'Changed Records'. 

1. `ssh deploy@bibdata-alma-worker-staging1`
2. `cd /opt/bibdata/current`
3. `bundle exec rails c`
4. Assuming that the env SOLR_URL=http://lib-solr8-staging.princeton.edu:8983/solr/catalog-staging find the index_manager that is currently used. `index_mgr=IndexManager.all.where(solr_collection: "http://lib-solr8-staging.princeton.edu:8983/solr/catalog-staging").first`
5. Make sure that `index_mgr.dump_in_progress_id=nil` and `index_mgr.in_progress = false`. If not set them and save. 
6. Find the previous event_id (which equals the dump_id) from the event you want to test reindexing and that has dump type 'Changed Records' and set it. For example if the previous dump that was indexed has id 1123 then `index_mgr.last_dump_completed_id = 1123` and `index_mgr.save`. 
7. Check https://bibdata-staging.princeton.edu/sidekiq/busy and click 'Live Poll'. The indexing process is fast.
8. Run `index_mgr.index_remaining!`. In https://bibdata-staging.princeton.edu/sidekiq/busy you will see a new job.
9. One way to test that the dump was indexed is to run `index_mgr.reload`. You should see that `last_dump_completed_id` is the event/dump id you wanted to test reindexing. `in_progress` should be `false`.
10. Another way would be to download the dump_file and manually check the timestamp of some of the mmsids in catalog-staging or in solr.
