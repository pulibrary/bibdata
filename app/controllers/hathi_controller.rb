class HathiController < ApplicationController

  def hathi_access_bib_status
    if params[:bib_id]
      @hathi_record = HathiAccess.where(bibid: params[:bib_id]).select(:bibid,:status,:origin,:oclc_number)
      render json: @hathi_record
    end
  end
end
