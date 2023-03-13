# frozen_string_literal: true

require "redis"

redis_config = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "redis.yml"))).result, aliases: true)[Rails.env].with_indifferent_access
redis_client = Redis.new(redis_config.merge(thread_safe: true))._client

Sidekiq::Client.reliable_push! unless Rails.env.test?
Sidekiq.configure_server do |config|
  config.redis = redis_client.options
  config.super_fetch!
  config.reliable_scheduler!
end

Sidekiq.configure_client do |config|
  config.redis = redis_client.options
end
