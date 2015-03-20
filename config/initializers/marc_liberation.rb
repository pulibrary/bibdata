require 'yaml'

MARC_LIBERATION_CONFIG ||= YAML.load_file("#{File.dirname(__FILE__)}/../marc_liberation.yml")

MARC_LIBERATION_CONFIG['data_dir'] = File.expand_path(MARC_LIBERATION_CONFIG['data_dir'])
