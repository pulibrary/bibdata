require 'yaml'
require_relative '../../voyager_helpers/lib/voyager_helpers'

vh_config = YAML.load_file("#{File.dirname(__FILE__)}/../voyager_helpers.yml")
VoyagerHelpers.configure do |config|
  config.du_user = vh_config.fetch('du_user')
  config.db_password = vh_config.fetch('db_password')
  config.db_name = vh_config.fetch('db_name')
end
