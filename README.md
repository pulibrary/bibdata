# Bibdata

Formerly known as MARC Liberation (since it liberates MARC data from Voyager).

[![CircleCI](https://circleci.com/gh/pulibrary/bibdata.svg?style=svg)](https://circleci.com/gh/pulibrary/bibdata)
[![CoverageStatus](https://coveralls.io/repos/github/pulibrary/bibdata/badge.svg?branch=main)](https://coveralls.io/github/pulibrary/bibdata?branch=main)
[![BSD 2-Clause License](https://img.shields.io/badge/license-BSD-blue.svg?style=plastic)](./LICENSE)

Find Internal Documentation on our [confluence
wiki](https://lib-confluence.princeton.edu/pages/viewpage.action?spaceKey=ALMA&title=Alma)

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
1. Install bundler version in Gemfile.lock
```
gem install bundler -v '2.2.27'
```
1. Install bundle
```
bundle install
```
1. To start: `bundle exec rake servers:start`
1. For testing:
   - `bundle exec rspec`
1. For development:
   - `bundle exec rails server`
   - Access marc_liberation at http://localhost:3000/
1. If you are working with background jobs in development, start sidekiq in a new tab or window
   - `bundle exec sidekiq`
   - To access the sidekiq dashboard, first sign into the application, then go to http://localhost:3000/sidekiq
1. To stop: `bundle exec rake servers:stop` or `lando stop`

## Tests

Ensure redis is running

To run the tests in the `marc_to_solr` directory set RAILS_ENV:
`$ RAILS_ENV=test bundle exec rspec marc_to_solr/spec`

To run all the tests use the rake task, which sets some environment variables for you:
`$ rake spec`

## Deploy
Deployment is through capistrano. To deploy a branch other than "main", prepend an environment variable to your deploy command, e.g.:
`BRANCH=my_feature bundle exec cap staging deploy`

## Production Locations Configuration

To import locations from Alma for the first time in a production environment do
the following:

1. `cap [environment] rails:console`
1. `LocationDataService.delete_existing_and_repopulate`

## API Endpoints
[API Endpoint documentation](docs/api_endpoints.md)

## Alma Webhooks
see [[webhook_monitor/README.md]]

## License

See `LICENSE`.
