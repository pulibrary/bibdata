# frozen_string_literal: true

module WithLibrary
  extend ActiveSupport::Concern
  included do
    belongs_to :library, class_name: 'Library', foreign_key: :library_id
    validates :library, presence: true
  end
end
