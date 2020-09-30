class DumpFilesController < ApplicationController
  before_action :set_dump_file, only: [:show]

  def show
    send_file @dump_file.path, file_name: File.basename(@dump_file.path), type: 'application/x-gzip'
  end

  private

    def set_dump_file
      @dump_file = DumpFile.find(params[:id])
    end

    def dump_file_params
      params.require(:dump_file).permit(:dump_id) # (:dump_id, :path, :md5)
    end
end
