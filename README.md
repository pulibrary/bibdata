# MARC Liberation

Liberate MARC data from Voyager.

## Configuration

Be sure to copy `config/initializers/voyager_helpers.rb.tmpl` to `config/initializers/voyager_helpers.rb`
and `config/initializers/devise.rb.tml` to `config/initializers/devise.rb`,
then fill out the appropriate values.

## Installation

Oci8 is a little bit of a pain. See `/voyager_helpers/README.md` for details.

### Using macOS/OS X releases and Homebrew

Please see [the RubyDoc for the ruby-oci8 Gem](http://www.rubydoc.info/github/kubo/ruby-oci8/file/docs/install-on-osx.md#Install_Oracle_Instant_Client_Packages) for how best to track versions of the Oracle Client packages in Apple OS environments.

## Services

For now look at `config/routes.rb` for what's available.

## License

See `LICENSE`.
