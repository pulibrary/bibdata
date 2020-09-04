class HathiController < ApplicationController

  def hathi_access_bib_status
    if params[:bib_id]
      @record = HathiAccess.where(bibid: params[:bib_id])
      render json: @record, except: [:id, :created_at, :updated_at]
    end
  end

  def hathi_access
    return hathi_access_bib if params[:bib_id]
    return hathi_access_oclc if params[:oclc]
  end

  def hathi_access_bib
    @record = HathiAccess.where(bibid: params[:bib_id])
    if @record.present?
      render json: @record, except: [:id, :created_at, :updated_at]
    else
      status_404
    end
  end

  def hathi_access_oclc
    @record = HathiAccess.where(oclc_number: params[:oclc])
    if @record.present?
      render json: @record, except: [:id, :created_at, :updated_at]
    else
      status_404
    end
  end

  def status_404
    render json: @record, status: 404
  end

end

