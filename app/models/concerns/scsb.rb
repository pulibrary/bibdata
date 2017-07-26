module Scsb
  extend ActiveSupport::Concern

  def parse_scsb_message(message)
    parsed = JSON.parse(message)
    parsed.class == Hash ? parsed.with_indifferent_access : parsed
  end
end
