# frozen_string_literal: true

module Coded
  extend ActiveSupport::Concern
  included do
    include FriendlyId
    friendly_id :code
    validates :code, presence: true
    validates :code, uniqueness: true
  end
end
