module Alma
	def config
	  @config ||= config_yaml.with_indifferent_access
	end

	private
  
  # do I need to specify the ENV in the config? Check the keys from Alma
	def config_yaml
	  YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "alma.yml"))).result, [], [], true)
	end

	module_function :config, :config_yaml
end