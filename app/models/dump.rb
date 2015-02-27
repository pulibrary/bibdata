class Dump < ActiveRecord::Base
  belongs_to :event
  has_one :dump_type
  has_many :dump_files
  serialize :delete_ids

  # TODO: validations based on dump type..maybe.
   
end
