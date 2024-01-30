# When a location changes in Alma:
* A ticket should be created first in [Alma Config repository](https://github.com/PrincetonUniversityLibrary/alma-config/issues) with all the necessary information. [Alma Config repository](https://github.com/PrincetonUniversityLibrary/alma-config) is a private repository and you may not have access. Please ask if you can gain access.  

## 1. Update the local dev environment: 

1. Update the necessary files in [bibdata locations directory](https://github.com/pulibrary/bibdata/tree/main/config/locations). 
   * If there is a new holding location then update the [holding_locations.json file](https://github.com/pulibrary/bibdata/blob/main/config/locations/holding_locations.json) with the appropriate information. 
   * If there is a new library then update the [libraries.json file](https://github.com/pulibrary/bibdata/blob/main/config/locations/libraries.json) with the new library following the pattern in the file. 
   * If there is a new delivery location then update the [delivery_locations.json file](https://github.com/pulibrary/bibdata/blob/main/config/locations/delivery_locations.json) with the appropriate information.

2. Run the following rake task to delete the existing data from the location tables and repopulate them using the config files:  
   `bundle exec rake bibdata:delete_and_repopulate_locations`

4. Run the following rake task to generate the following rb files: marc_to_solr/translation_maps/location_display.rb and marc_to_solr/translation_maps/locations.rb
  `bundle exec rake bibdata:generate_location_rbfiles`

5. Copy the content from the generated .rb files into the .tmpl.rb files  
  `cp marc_to_solr/translation_maps/location_display.rb marc_to_solr/translation_maps/location_display.rb.tmpl`  
  `cp marc_to_solr/translation_maps/locations.rb marc_to_solr/translation_maps/locations.rb.tmpl`

6. Load locally the rails server; Go to: `localhost:<portnumber>/locations/holding_locations` in your browser and make sure that the locations have been updated.

## 2. Update Bibdata staging
Test the updated locations in [Bibdata staging](https://bibdata-staging.princeton.edu/)
Deploy your branch on staging and run the following steps to make sure that nothing is breaking the tables.

1. Connect in one of the bibdata staging boxes:   
  `ssh deploy@bibdata-alma-worker-staging1`  
  `cd /opt/bibdata/current`  

2. Run the following rake task to delete and repopulate the locations in the bibdata staging database:  
  `RAILS_ENV=production bundle exec rake bibdata:delete_and_repopulate_locations`

3. Review the changes in [Bibdata staging](https://bibdata-staging.princeton.edu/).

## 3. Update Bibdata qa
Test the updated locations in [Bibdata qa](https://bibdata-qa.princeton.edu/).
Deploy your branch on qa and run the following steps to make sure that nothing is breaking the tables.

1. Connect in one of the bibdata qa boxes:   
  `ssh deploy@bibdata-worker-qa1`  
  `cd /opt/bibdata/current`  

2. Run the following rake task to delete and repopulate the locations in the bibdata qa database:  
  `RAILS_ENV=production bundle exec rake bibdata:delete_and_repopulate_locations`

3. Review the changes in [Bibdata qa](https://bibdata-qa.princeton.edu/)

*If it runs successfully merge and deploy to production; go to the next step to update the location tables in production.*
## 4. Update Bibdata production
### Don't update the locations in Bibdata production during indexing hours. Please see [Alma Publishing Jobs Schedule](https://github.com/pulibrary/bibdata/blob/main/docs/alma_publishing_jobs_schedule.md).
The indexing takes place after the [Alma Publishing Job](https://github.com/pulibrary/bibdata/blob/main/docs/alma_publishing_jobs_schedule.md) completes and an event is created with a `Finish` timestamp and `Success: true` in bibdata.

1. Connect in one of the bibdata production boxes:  
  `ssh deploy@bibdata-alma-worker1`  
  `cd /opt/bibdata/current`  

2. Run the following rake task to delete and repopulate the locations in the production database:  
  `RAILS_ENV=production bundle exec rake bibdata:delete_and_repopulate_locations`

3. Review the changes in [Bibdata](https://bibdata.princeton.edu/).
