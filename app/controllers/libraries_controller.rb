# frozen_string_literal: true

class LibrariesController < ApplicationController
  before_action :set_library, only: %i[show]

  # GET /libraries
  def index
    @libraries = Library.all.order(:order, :label)
  end

  # GET /libraries/1
  def show; end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_library
      # nosemgrep
      @library = Library.friendly.find(params[:id])
    end
end
