# When a location changes in Alma:
* The Alma-Tech team will create a first ticket in [Alma Config repository](https://github.com/PrincetonUniversityLibrary/alma-config/issues) with all the necessary information. [Alma Config repository](https://github.com/PrincetonUniversityLibrary/alma-config) is a private repository and you may not have access. Please ask if you can gain access.
* The Alma-Tech team will create a second maintenance ticket in [Bibdata repository](https://github.com/pulibrary/bibdata/issues/new?assignees=&labels=maintenance&projects=&template=maintenance-task.md&title=).  

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

1. Deploy your branch on staging and follow the steps to make sure that nothing is breaking the tables:

2. Stop the workers (this step is optional in staging): 
    - cd in your local princeton_ansible directory → pipenv shell → `ansible bibdata_staging -u pulsys -m shell -a "sudo service bibdata-workers stop"`. (Ignore the console error for the bibdata staging web servers. They don't run the worker service.)     

3. Connect in one of the [bibdata_staging workers](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/bibdata#L9C1-L10):
    
    - `ssh deploy@bibdata-worker-staging1.lib.princeton.edu`  
    - `cd /opt/bibdata/current` 

4. Run the following rake task to delete and repopulate the locations in the bibdata staging database:  
  `RAILS_ENV=production bundle exec rake bibdata:delete_and_repopulate_locations`

5. Review the location changes in [Bibdata staging](https://bibdata-staging.lib.princeton.edu/).

6. If in step 2 you stopped the workers then start the workers: 
    - cd in your local princeton_ansible directory → pipenv shell → `ansible bibdata_staging -u pulsys -m shell -a "sudo service bibdata-workers start"`. (Ignore the console error for the bibdata staging web servers. They don't run the worker service.)   

7. Deploy orangelight 
   or 
   ssh in one of the [orangelight staging VMs](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/orangelight#L37-L38) and run the rake task to clear the cache:
   `cd /opt/orangelight/current`
   `bundle exec rake cache:clear`

## 3. Update Bibdata QA

1. Deploy your branch on qa and follow the steps to make sure that nothing is breaking the tables.

2. Stop the workers (this step is optional in QA): 
    - cd in your local princeton_ansible directory → pipenv shell → `ansible bibdata_qa -u pulsys -m shell -a "sudo service bibdata-workers stop"`. (Ignore the console error for the bibdata qa web servers. They don't run the worker service.) 

3. Connect in one of [bibdata-qa workers](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/bibdata#L4-L5):    
    - `ssh deploy@bibdata-worker-qa1.princeton.edu`  
    - `cd /opt/bibdata/current`  

4. Run the following rake task to delete and repopulate the locations in the bibdata qa database:  
  `RAILS_ENV=production bundle exec rake bibdata:delete_and_repopulate_locations`

5. Review the changes in [Bibdata qa](https://bibdata-qa.princeton.edu/)
6.  If in step 2 you stopped the workers then start the workers:
    - cd in your local princeton_ansible directory → pipenv shell → `ansible bibdata_qa -u pulsys -m shell -a "sudo service bibdata-workers start"`. (Ignore the console error for the bibdata qa web servers. They don't run the worker service)  
7. Deploy orangelight 
   or 
   ssh in one of the [orangelight QA VMs](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/orangelight#L24-L25) and run the rake task to clear the cache:
   `cd /opt/orangelight/current`
   `bundle exec rake cache:clear`  

*If there were no errors updating the location tables in QA or in staging, merge the branch and go to the next step to update the location tables in production.*
## 4. Update Bibdata production

1. Deploy the main branch to production.   

2. Stop the workers: 
    - cd in your local princeton_ansible directory → pipenv shell → `ansible bibdata_production -u pulsys -m shell -a "sudo service bibdata-workers stop"`. (Ignore the console error for the bibdata production web servers. They don't run the worker service) . 

3. Connect in one of [bibdata-production workers](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/bibdata#L14-L15):    
    - `ssh deploy@bibdata-worker-prod1.princeton.edu`  
    - `cd /opt/bibdata/current`  

4. Run the following rake task to delete and repopulate the locations in the bibdata production database:  
  `RAILS_ENV=production bundle exec rake bibdata:delete_and_repopulate_locations`

5. Review the changes in [Bibdata production](https://bibdata.princeton.edu/)

6. Start the workers:
    - cd in your local princeton_ansible directory → pipenv shell → `ansible bibdata_production -u pulsys -m shell -a "sudo service bibdata-workers start"`. (Ignore the console error for the bibdata production web servers. They don't run the worker service)

7. Deploy orangelight 
   or 
   ssh in one of the [orangelight production VMs](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/orangelight#L7-L11) and run the rake task to clear the cache:
   `cd /opt/orangelight/current`
   `bundle exec rake cache:clear`
