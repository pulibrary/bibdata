# MARC Liberation

Liberate MARC data from Voyager.

## Services

For now look at `config/routes.rb` for what's available.

## Development and testing

## Installation

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

## Tests

A couple of the tests require some fixtures to be in place; for now they must be copied as in this CI configuration: https://github.com/pulibrary/marc_liberation/blob/master/circle.yml#L8-L10

Ensure redis is running

## License

See `LICENSE`.
