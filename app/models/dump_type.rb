class DumpType < ActiveRecord::Base
  PARTNER_RECAP_FULL = 'PARTNER_RECAP_FULL'.freeze

  has_many :dumps
end
