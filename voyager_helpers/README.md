# Voyager Helpers

A set of methods for retrieving data from Voyager.

## Installation

On __Ubuntu__ systems, do [this](https://help.ubuntu.com/community/Oracle%20Instant%20Client). __All of it.__

Add configuration for VGER In `$ORACLE_HOME/network/admin/tnsnames.ora` (ask DBA).

In `/etc/profile.d/oracle.sh` Append:

```
export ORACLE_LIB=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
```

To the variables you added earlier.

On __MacOSX__, follow the [ruby-oci8 instructions for setting up Oracle with Homebrew]
(http://www.rubydoc.info/gems/ruby-oci8/file/docs/install-on-osx.md), and set the `TNS_ADMIN`
variable to the directory containing your `tnsnames.ora` config file.  These instructions
install the 11.2 client, which works fine with 10.2 Oracle servers.

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
