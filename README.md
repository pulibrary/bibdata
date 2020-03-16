# MARC Liberation

Liberate MARC data from Voyager.

## Services

For now look at `config/routes.rb` for what's available.

## Development and testing

## Installation

### Dependencies
  * Mysql
  * PhantomJS

### Oci8

Oci8 is a little bit of a pain. See `https://github.com/pulibrary/voyager_helpers/blob/master/README.md` for details.

#### Using macOS/OS X releases and Homebrew

As referenced in the above readme, use [the RubyDoc for the ruby-oci8 Gem](http://www.rubydoc.info/github/kubo/ruby-oci8/file/docs/install-on-osx.md#Install_Oracle_Instant_Client_Packages) for how best to track versions of the Oracle Client packages in Apple OS environments.

## Configuration

Set env vars in `config/initializers/voyager_helpers.rb` and `config/initializers/devise.rb`, as appropriate.

You can run tests without setting up a voyager connection, but it is required for a development environment.

## Database Configuration

Prepend the below with `RUBY_ENV=test` as appropriate

```bash
rake db:create
rake db:migrate
rake db:seed
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

## Export the location data
1. export the database in production
  ```
  ssh deploy@bibdata1
  cd /opt/marc_liberation/current
  RAILS_ENV=production bundle exec rake db:data:dump
  exit
  ```
1. copy the file locally 
  ```
  scp deploy@bibdata1:/opt/marc_liberation/current/db/data.yml db/data.yml
  ```
1. edit the dump and remove everything except `locations_*` . Move locations_library first and locations_hours_locations second

1. to update the database you need to clear it and then load it: `rake db:drop db:create db:migrate db:data:load db:seed`

## Tests

A couple of the tests require some fixtures to be in place; for now they must be copied as in this CI configuration: https://github.com/pulibrary/marc_liberation/blob/6b7b9e60d65f313fede5a70e5a2cd6e56d634003/.circleci/config.yml#L36-L46

Ensure redis is running

To run the tests in the `marc_to_solr` directory set RAILS_ENV:
`$ RAILS_ENV=test bundle exec rspec marc_to_solr/spec`

To run all the tests use the rake task, which sets some environment variables for you:
`$ rake spec`

## Deploy
Deployment is through capistrano. To deploy a branch other than "master", prepend an environment variable to your deploy command, e.g.:
`BRANCH=my_feature bundle exec cap staging deploy`

## License

See `LICENSE`.
