# frozen_string_literal: true

module Labeled
  extend ActiveSupport::Concern

  included do
    validates :label, presence: true
  end
end
