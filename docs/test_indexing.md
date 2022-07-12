### Scenario 1
## Test indexing a specific .xml file

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
   cd /opt/marc_liberation/current
   ``` 
1. run `SET_URL=http://lib-solr8-staging.princeton.edu:8983/solr/catalog-staging FILE=/home/deploy/<file name>.xml RAILS_ENV=production bundle exec rake liberate:index_file` 
