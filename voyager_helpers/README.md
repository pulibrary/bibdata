# Voyager Helpers

A set of methods for retrieving data from Voyager.

## Installation

On Ubuntu systems, do [this](https://help.ubuntu.com/community/Oracle%20Instant%20C). __All of it.__

Add configuration for VGER In `$ORACLE_HOME/network/admin/tnsnames.ora` (ask DBA).

In `/etc/profile.d/oracle.sh` Append:

```
export ORACLE_LIB=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
```

To the variables you added earlier, and, finally, add this line to your application's Gemfile:

```ruby
gem 'marc_liberation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install marc_liberation


## Configuration

The gem needs to know the database username, password and database name. Put 
this somewhere:

```ruby
VoyagerHelpers.configure do |config|
  config.du_user = 'foo'
  config.db_password = 'quux'
  config.db_name = 'VOYAGER'
end
```

(Like in an initializer if you're using Rails)

## Usage

Once everything is installed and configured, usage is pretty straightforward:

```ruby
record = VoyagerHelpers::Liberator.get_bib_record(4609321)
record.inspect
 => [#<MARC::Record:0x000000031781c8 @fields=[#<MARC::ControlField:0x00 ...
```

## Contributing

1. Fork it ( https://github.com/pulibrary/marc_liberation/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
