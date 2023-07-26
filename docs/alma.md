# Alma

## Configure Alma keys for Development

1. `lpass login emailhere`
1. `bundle exec rake alma:setup_keys`

This will add a .env with credentials to Rails.root

## Accessing the Alma Development instance

Use your netid and password to login and access [Alma Development instance](https://princeton-psb.alma.exlibrisgroup.com/SAML).

### Trigger an incremental job in the alma sandbox

1. Login in [Alma Development instance](https://princeton-psb.alma.exlibrisgroup.com/SAML). Use your netid and password.
2. In the left nav bar click on 'Resources' → 'Publishing Profiles'. This will return a list of the 'Publishing Profiles'.
3. Find the one that is called 'Incremental Publishing'. 
4. Click the ellipsis button.
5. Click Run. 
This will trigger an incremental job in the alma sandbox. It takes around 45-60 minutes to complete. 
If there are updated records then in [bibdata staging events](https://bibdata-staging.princeton.edu/events) a new event will be created with the 'dump type': 'Changed Records'. This event holds a dump file from the incremental dump that was triggered in the alma sandbox. [Example](https://bibdata-staging.princeton.edu/dumps/1124.json) with two dump_files.
In [bibdata staging sidekiq](https://bibdata-staging.princeton.edu/sidekiq) you can see the indexing progress. Keep in mind that it is fast and you might not notice the indexing job in the dashboard.
The indexing process uses the value of the env SOLR_URL that you can see if you ssh in bibdata-alma-staging1.

## Accessing the Alma Production instance

Login using the princeton netid to access [Alma Production instance](https://princeton.alma.exlibrisgroup.com/SAML).

## Accessing the Exlibris Developer network/ API console

[Exlibris console](https://developers.exlibrisgroup.com/console/)

If you don't have an account, ask our local administrator to create one for you.

1. You will get an invitation email and be prompted to create an account
2. Once the account is created, wait for a 2nd email to activate that account
3. Once you've activated the account, go back to the first email and use the
   bottom link to accept the invitation. You should now have access to our keys.

## Creating Alma Fixtures

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

## Export a set of test records from production
1. Login to [Alma](https://princeton.alma.exlibrisgroup.com/SAML).
1. In the left side bar click 'Admin' → Select 'Manage sets'
1. Find or create the set you want to use.
1. Click on the elipsis button of the set. → Select 'Members'
1. If there are records in the set that it is not desired to export, select the records using the checkbox to the left and click 'Remove Selected'
1. Click 'Add Members'. Add in the search bar the desired mms_id. → 'Search' → Select the listed record using the checkbox → Click Add Selected.
1. In the left bar, click 'Resources' → 'Publishing Profiles' → Find the 'DRDS Test Record export' publishing profile.
1. → Click the elipsis button and select 'Edit'. Configure it to use your set under "Content". Click "Save".
1. → Click the elipsis button and select 'Republish'. → Select 'Rebuild Entire Index' → Click 'Run Now'.
1. The new tar.gz file with the selected records will be on the lib-sftp server as '/alma/drds_test_records_new[_i].tar.gz'

## Finding a Voyager item in Alma

Voyager items, once the migration is finished, will have an ID in Alma equal to
`99<voyager_id>3506421`

## Hitting the Alma API

The Alma web API has a maximum concurrent hit limit of 25 / second. Please see [API Limits documentation](https://developers.exlibrisgroup.com/alma/apis/#threshold) and [Daily Use stats](https://developers.exlibrisgroup.com/manage/reports/).
