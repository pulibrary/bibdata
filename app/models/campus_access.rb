require 'csv'

class CampusAccess < ActiveRecord::Base
  def self.has_access?(uid)
    where(uid: uid).count.positive?
  end
  def self.to_csv
    ::CSV.generate(headers: false) do |csv|
      all.each do |user|
        csv << [user.uid]
      end
    end
  end
end
