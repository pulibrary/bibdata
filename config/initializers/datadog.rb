# frozen_string_literal: true
if Rails.env.production?
  Datadog.configure do |c|
    c.env = 'production'
    # c.service = 'bibdata'
    # Rails
    c.tracing.instrument :rails
  
    # Redis
    c.tracing.instrument :redis
  
    # Net::HTTP
    c.tracing.instrument :http
  
    # Sidekiq
    c.tracing.instrument :sidekiq
  
    # Faraday
    c.tracing.instrument :faraday
  end
end
