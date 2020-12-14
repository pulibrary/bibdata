# frozen_string_literal: true

begin
  # This determines which services are running, as `lando info` does not exclude containers which are not active.
  lando_list = JSON.parse(`lando list --format json`, symbolize_names: true)
rescue StandardError => error
  Rails.logger.warn("Failed to find the `lando` containers in the environment (is Lando installed?)")
  lando_list = []
end

if !lando_list.empty? && (Rails.env.development? || Rails.env.test?)
  begin
    lando_services = JSON.parse(`lando info --format json`, symbolize_names: true)
    lando_services.each do |service|
      service[:external_connection]&.each do |key, value|
        ENV["lando_#{service[:service]}_conn_#{key}"] = value
      end
      next unless service[:creds]
      service[:creds].each do |key, value|
        ENV["lando_#{service[:service]}_creds_#{key}"] = value
      end
    end
  rescue StandardError => error
    Rails.logger.warn("Failed to start the container services using Lando: #{error}")
  end
end
