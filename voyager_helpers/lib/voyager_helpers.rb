%w{
  change_report
  liberator
  oracle_connection
  queries
  resource_report
  sync_fu
}.each do |f|
  require_relative "voyager_helpers/#{f}"
end
require 'active_support/configurable'

module VoyagerHelpers

  include ActiveSupport::Configurable

  class << self

    def configure
      yield(config)
    end

  end # class << self
end # module VoyagerHelpers

