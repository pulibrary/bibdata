require 'yaml'

LANGUAGES ||= YAML.load_file("#{File.dirname(__FILE__)}/../iso639.yml")
