# Bibdata

Formerly known as MARC Liberation (since it liberates MARC data from Voyager).

[![CircleCI](https://circleci.com/gh/pulibrary/bibdata.svg?style=svg)](https://circleci.com/gh/pulibrary/bibdata)
[![CoverageStatus](https://coveralls.io/repos/github/pulibrary/bibdata/badge.svg?branch=main)](https://coveralls.io/github/pulibrary/bibdata?branch=main)
[![BSD 2-Clause License](https://img.shields.io/badge/license-BSD-blue.svg?style=plastic)](./LICENSE)

Find Internal Documentation on our [confluence
wiki](https://lib-confluence.princeton.edu/pages/viewpage.action?spaceKey=ALMA&title=Alma)

## Services

For now look at `config/routes.rb` for what's available.

## Development and testing

### Dependencies
  * Postgresql (provided in development by lando)

Note: You need to have PostgreSQL installed in your machine and available in your path for the `pg` gem to compile native extensions (e.g. `export PATH=$PATH:/Library/PostgreSQL/10/bin/`).

### Config files
You'll need to copy a few files manually [as indicated in the CircleCI config file](https://github.com/pulibrary/marc_liberation/blob/6b7b9e60d65f313fede5a70e5a2cd6e56d634003/.circleci/config.yml#L36-L46).

### Setup server
1. Install Lando from https://github.com/lando/lando/releases (at least 3.0.0-rrc.2)
1. To start: `bundle exec rake marc_liberation:server:start`
1. For testing:
   - `bundle exec rspec`
1. For development:
   - `bundle exec rails server`
   - Access marc_liberation at http://localhost:3000/
1. To stop: `bundle exec rake marc_liberation:server:stop` or `lando stop`

## Alma

### Configure Alma keys for Development

1. `brew install lastpass-cli`
2. `lpass login emailhere`
3. `bundle exec rake alma:setup_keys`

This will add a .env with credentials to Rails.root

### Accessing the Alma instance

https://sandbox02-na.alma.exlibrisgroup.com/mng/login?institute=01PRI_INST&auth=local

Credentials are in LastPass; use the AlmaAdmin account

## Accessing the API sandbox

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

### Finding a Voyager item in Alma

Voyager items, once the migration is finished, will have an ID in Alma equal to
`99<voyager_id>3405314`

## Database Configuration

```bash
createdb marc_liberation_dev
RAILS_ENV=development rake db:migrate
RAILS_ENV=development rake db:seed

createdb marc_liberation_test
RAILS_ENV=test rake db:migrate
RAILS_ENV=test rake db:seed
```

Get data from the production server
```
ssh deploy@bibdata1
cat app_configs/marc_liberation # grab the password
pg_dump -h $BIBDATA_DB_HOST -U $BIBDATA_DB_USERNAME marc_liberation_prod > marc_liberation.dump
exit
```
import the data to you local machine
```
cd <your location for marc_liberation>
scp deploy@bibdata1:marc_liberation.dump .
vi marc_liberation.dump
:%s/marc_liberation_prod/marc_liberation_dev/g
:wq
```
Import data into your local database
```
rake db:drop
createdb marc_liberation_dev
psql marc_liberation_dev < marc_liberation.dump
rake db:migrate
rails db:environment:set RAILS_ENV=development
psql marc_liberation_dev
alter database marc_liberation_dev set search_path to marc_liberation_dev, public;
```

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

### Indexing a single record

To index a single record from Voyager into Orangelight:

```
SET_URL=http://localhost:8983/solr/orangelight-core-development BIB=123456 rake liberate:bib
```

## Alma Webhooks
see [[webhook_monitor/README.md]]

## Tests

A couple of the tests require some fixtures to be in place; for now they must be copied as in this CI configuration: https://github.com/pulibrary/marc_liberation/blob/6b7b9e60d65f313fede5a70e5a2cd6e56d634003/.circleci/config.yml#L36-L46

Ensure redis is running

To run the tests in the `marc_to_solr` directory set RAILS_ENV:
`$ RAILS_ENV=test bundle exec rspec marc_to_solr/spec`

To run all the tests use the rake task, which sets some environment variables for you:
`$ rake spec`

## Deploy
Deployment is through capistrano. To deploy a branch other than "main", prepend an environment variable to your deploy command, e.g.:
`BRANCH=my_feature bundle exec cap staging deploy`

## License

See `LICENSE`.
