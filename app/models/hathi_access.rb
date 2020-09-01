class HathiAccess < ActiveRecord::Base
  validates :status, inclusion: { in: %w(ALLOW DENY) }
  validates :origin, inclusion: { in: %w(CUL PUL) }
end
