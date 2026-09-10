# frozen_string_literal: true

module WithLibrary
  extend ActiveSupport::Concern

  included do
    belongs_to :library, class_name: 'Library', foreign_key: :locations_library_id
    # rubocop:disable-next Rails/RedundantPresenceValidationOnBelongsTo
    validates :library, presence: true
  end
end
