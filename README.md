# Bibdata

Formerly known as MARC Liberation (since it liberates MARC data from Voyager).

[![CircleCI](https://circleci.com/gh/pulibrary/bibdata.svg?style=svg)](https://circleci.com/gh/pulibrary/bibdata)
[![CoverageStatus](https://coveralls.io/repos/github/pulibrary/bibdata/badge.svg?branch=main)](https://coveralls.io/github/pulibrary/bibdata?branch=main)
[![BSD 2-Clause License](https://img.shields.io/badge/license-BSD-blue.svg?style=plastic)](./LICENSE)

Find Internal Documentation on our [confluence
wiki](https://lib-confluence.princeton.edu/pages/viewpage.action?spaceKey=ALMA&title=Alma)

## API Endpoints

[API Endpoint documentation](docs/api_endpoints.md)

## Development and testing

### Dependencies
  * Postgresql (provided in development by lando)
  * `brew install lastpass-cli`
  * `brew install shared-mime-info` (for `mimemagic` gem)

Note: You need to have PostgreSQL installed in your machine and available in your path for the `pg` gem to compile native extensions (e.g. `export PATH=$PATH:/Library/PostgreSQL/10/bin/`).

### Setup server
1. Install Lando from https://github.com/lando/lando/releases (at least 3.0.0-rrc.2)
1. Install Sidekiq Pro credentials:
```
lpass login emailhere
bin/setup_keys
```
1. To start: `bundle exec rake servers:start`
1. For testing:
   - `bundle exec rspec`
1. For development:
   - `bundle exec rails server`
   - Access marc_liberation at http://localhost:3000/
1. To stop: `bundle exec rake servers:stop` or `lando stop`

## Alma

### Configure Alma keys for Development

1. `lpass login emailhere`
1. `bundle exec rake alma:setup_keys`

This will add a .env with credentials to Rails.root

### Accessing the Alma Development instance

https://princeton-psb.alma.exlibrisgroup.com

Credentials are in LastPass; use the `disc0001` account

### Accessing the Alma Production instance

https://princeton.alma.exlibrisgroup.com/SAML

Login using the princeton netid.

### Accessing the Exlibris Developer network/ API console

https://developers.exlibrisgroup.com/console/

If you don't have an account ask our local administrator to create one for you.

1. You will get an invitation email and be prompted to create an account
1. Once the account is created, wait for a 2nd email to activate that account
1. Once you've activated the account, go back to the first email and use the
   bottom link to accept the invitation. You should now have access to our keys.

### Creating Alma Fixtures

In the API sandbox (see above)

1. Select the 'api-na' north america server
1. Select the read-only API key
1. Click the api endpoint you want to use
1. Click 'try it out'
1. Set all desired parameters
1. Select media type: application/json or application/xml (below the 'Execute'
   button)
1. Click 'Execute'
1. You can download the file with the little "Download" button

### Export a set of test records from production
1. Login to alma https://princeton.alma.exlibrisgroup.com/SAML
1. In the left side bar click 'Admin' -> Select 'Manage sets'
1. Find or create the set you want to use.
1. Click on the elipsis button of the set. -> Select 'Members'
1. If there are records in the set that it is not desired to export, select the records using the checkbox to the left and click 'Remove Selected'
1. Click 'Add Members'. Add in the search bar the desired mms_id. -> 'Search' -> Select the listed record using the checkbox -> Click Add Selected.
1. In the left bar, click 'Resources' -> 'Publishing Profiles' -> Find the 'DRDS Test Record export' publishing profile.
1. -> Click the elipsis button and select 'Edit'. Configure it to use your set under "Content". Click "Save".
1. -> Click the elipsis button and select 'Republish'. -> Select 'Rebuild Entire Index' -> Click 'Run Now'.
1. The new tar.gz file with the selected records will be on the lib-sftp server as '/alma/drds_test_records_new[_i].tar.gz'

### Finding a Voyager item in Alma

Voyager items, once the migration is finished, will have an ID in Alma equal to
`99<voyager_id>3506421`

### Hitting the Alma API

The Alma web API has a maximum concurrent hit limit of 25 / second. The API limits are documented at https://developers.exlibrisgroup.com/alma/apis/#threshold and Daily use stats can be viewed at https://developers.exlibrisgroup.com/manage/reports/.

## ARK Caching

In order to resolve bibliographic identifiers (bib. IDs) to resources with ARKs and IIIF manifests for resources managed within digital repositories, caches are seeded and used in order to resolve the relationships between these resources.

### Seeding the Cache

One may seed the cache using the following Rake Task:
```bash
rake liberate:arks:seed_cache
```

### Clearing the Cache

One may clear the cache using the following Rake Task:
```bash
rake liberate:arks:clear_cache
```

## Alma Webhooks
see [[webhook_monitor/README.md]]

## MARC Files
If you have MARC file you can import it to Solr via Traject with the following commands:

```
FILE=/path/to/marc/file/filename.xml
SOLR_URL=http://localhost:8983/local-solr-index
bundle exec traject -c marc_to_solr/lib/traject_config.rb $FILE -u $SOLR_URL
```

If you just want to see what would be sent to Solr (but don't push the document to Solr) you can use instead:

```
FILE=/path/to/marc/file/filename.xml
bundle exec traject -c marc_to_solr/lib/traject_config.rb $FILE -w Traject::JsonWriter
```
OR with solr in any port:
```
traject -c marc_to_solr/lib/traject_config.rb path-to-xml/example.xml -u http://localhost:<solr-port-number>/solr/local-solr-index -w Traject::JsonWriter
```

## Tests

Ensure redis is running

To run the tests in the `marc_to_solr` directory set RAILS_ENV:
`$ RAILS_ENV=test bundle exec rspec marc_to_solr/spec`

To run all the tests use the rake task, which sets some environment variables for you:
`$ rake spec`

## Deploy
Deployment is through capistrano. To deploy a branch other than "main", prepend an environment variable to your deploy command, e.g.:
`BRANCH=my_feature bundle exec cap staging deploy`

## When a location changes in Alma:

#### 1. Update the local dev environment:

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

Test the updated locations in Bibdata-staging https://bibdata-staging.princeton.edu/ which is connected to the alma-sandbox; 
The locations will not be the same as in production because they are not up to date. Deploy your branch on staging and run the following steps to make sure that nothing is breaking the tables.

Connect in one of the bibdata staging boxes:
1.`ssh deploy@bibdata-alma-staging1`
2.`cd /opt/marc_liberation/current`
3.`RAILS_ENV=production bundle exec rails c`

Delete and repopulate the locations in the bibdata staging database:
4.`LocationDataService.delete_existing_and_repopulate`

*If it runs successfully merge and deploy to production; go to the next step to update the location tables in production.*

#### 2. Update Bibdata production:
Option 1:
Connect in one of the bibdata production boxes:
1.`ssh deploy@bibdata-alma1`
2.`cd /opt/marc_liberation/current`
3.`RAILS_ENV=production bundle exec rails c`

Delete and repopulate the locations in the production database:
4.`LocationDataService.delete_existing_and_repopulate`

Option 2:
Capistrano task to connect to the production rails console:
1. `cap production rails:console`

Delete and repopulate the locations in the production database:
1. `LocationDataService.delete_existing_and_repopulate`

## Production Locations Configuration

To import locations from Alma for the first time in a production environment do
the following:

1. `cap [environment] rails:console`
1. `LocationDataService.delete_existing_and_repopulate`

## License

See `LICENSE`.
