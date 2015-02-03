class DumpFilesController < ApplicationController
  before_action :set_dump_file, only: [:show]#, :edit, :update, :destroy]

  respond_to :json

  # def index
  #   @dump_files = DumpFile.all
  #   respond_with(@dump_files)
  # end

  def show
    respond_with(@dump_file)
  end

  # def new
  #   @dump_file = DumpFile.new
  #   respond_with(@dump_file)
  # end

  # def edit
  # end

  # def create
  #   @dump_file = DumpFile.new(dump_file_params)
  #   @dump_file.save
  #   respond_with(@dump_file)
  # end

  # def update
  #   @dump_file.update(dump_file_params)
  #   respond_with(@dump_file)
  # end

  # def destroy
  #   @dump_file.destroy
  #   respond_with(@dump_file)
  # end

  private
    def set_dump_file
      @dump_file = DumpFile.find(params[:id])
    end

    def dump_file_params
      params.require(:dump_file).permit(:dump_id)#(:dump_id, :path, :md5)
    end
end
