class DumpsController < ApplicationController
  before_action :set_dump, only: [:show] # , :edit, :update, :destroy]

  respond_to :json

  # def index
  #   Use /events!
  # end

  def show
    respond_with(@dump)
  end

  private

    def set_dump
      @dump = Dump.find(params[:id])
    end

    def dump_params
      params.require(:dump).permit(:dump_id) # (:dump_id, :path, :md5)
    end
end
