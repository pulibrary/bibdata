# frozen_string_literal: true

require "capybara/rspec"
require "selenium-webdriver"

Capybara.default_max_wait_time = 60
Capybara.server = :puma, { Silent: true }

RSpec.configure do |config|
  # set system spec driver depending on whether we use javascript in the test
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    if ENV["RUN_IN_BROWSER"]
      driven_by(:selenium_chrome)
    else
      driven_by(:selenium_chrome_headless)
    end
  end
  config.before(:each, type: :system, js: true, in_browser: true) do
    driven_by(:selenium_chrome)
  end
end
