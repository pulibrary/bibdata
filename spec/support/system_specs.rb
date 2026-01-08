# frozen_string_literal: true

require 'capybara/rspec'

Capybara.default_max_wait_time = 60
Capybara.server = :puma, { Silent: true }

RSpec.configure do |config|
  # set system spec driver depending on whether we use javascript in the test
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    if ENV['RUN_IN_BROWSER']
      driven_by(:selenium_chrome)
    else
      driven_by(:selenium_chrome_headless)
    end
  end
  config.before(:each, :in_browser, :js, type: :system) do
    driven_by(:selenium_chrome)
  end
end
