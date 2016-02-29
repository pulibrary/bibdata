require 'json'

RELATORS ||= JSON.parse(File.read("#{File.dirname(__FILE__)}/../../public/mrel/context.json"))['@context'].keys
