require 'yaml'
include VoyagerHelpers::OracleConnection

vh_config = YAML.load_file("#{File.dirname(__FILE__)}/../voyager_helpers.yml")

VoyagerHelpers.configure do |config|
  config.db_user = vh_config.fetch('du_user')
  config.db_password = vh_config.fetch('db_password')
  config.db_name = vh_config.fetch('db_name')
end


