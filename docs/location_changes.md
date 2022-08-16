# When a location changes in Alma:

### 1. Update the local dev environment:

Load the rails console
1.`bundle exec rails c`

Delete the existing data from the location tables and repopulate them by pulling data from Alma.
2.`LocationDataService.delete_existing_and_repopulate`

Generate the following files: marc_to_solr/translation_maps/location_display.rb and marc_to_solr/translation_maps/locations.rb
3.`LocationMapsGeneratorService.generate`

Copy the content from the generated .rb files into the .tmpl.rb files
4.`cp marc_to_solr/translation_maps/location_display.rb marc_to_solr/translation_maps/location_display.rb.tmpl`
`cp marc_to_solr/translation_maps/locations.rb marc_to_solr/translation_maps/locations.rb.tmpl`

Load locally the rails server; Go to `localhost:<portnumber>/locations/holding_locations` and make sure that the locations have been updated.

### 2. Update Bibdata staging
Test the updated locations in Bibdata-staging https://bibdata-staging.princeton.edu/ which is connected to the alma-sandbox;
The locations will not be the same as in production because they are not up to date. Deploy your branch on staging and run the following steps to make sure that nothing is breaking the tables.

Connect in one of the bibdata staging boxes:
1.`ssh deploy@bibdata-alma-staging1`
2.`cd /opt/bibdata/current`
3.`RAILS_ENV=production bundle exec rails c`

Delete and repopulate the locations in the bibdata staging database:
4.`LocationDataService.delete_existing_and_repopulate`

*If it runs successfully merge and deploy to production; go to the next step to update the location tables in production.*

### 3. Update Bibdata production:
Option 1:
Connect in one of the bibdata production boxes:
1.`ssh deploy@bibdata-alma1`
2.`cd /opt/bibdata/current`
3.`RAILS_ENV=production bundle exec rails c`

Delete and repopulate the locations in the production database:
4.`LocationDataService.delete_existing_and_repopulate`

Option 2:
Capistrano task to connect to the production rails console:
1. `cap production rails:console`

Delete and repopulate the locations in the production database:
1. `LocationDataService.delete_existing_and_repopulate`
