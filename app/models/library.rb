# frozen_string_literal: true

class Library < ActiveRecord::Base
  include Labeled
  include Coded

  # TODO: Remove after migrating to non-prefixed tables
  self.table_name_prefix = 'locations_'
end
