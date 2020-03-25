class PatronController < ApplicationController
  before_action :protect

  def patron_info
    data = VoyagerHelpers::Liberator.get_patron_info(sanitize(params[:patron_id]))
    if data.blank?
      render json: {}, status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(data) }
      end
    end
  end

  def patron_codes
    data = VoyagerHelpers::Liberator.get_patron_stat_codes(sanitize(params[:patron_id]))
    if data.blank?
      render json: {}, status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(data) }
      end
    end
  end

  private
  def protect
    unless user_signed_in?
      render plain: "You are unauthorized", status: 403 if not check_ip(request.remote_ip)
    end
  end

  def check_ip(ip)
    ip_whitelist.any? { |ip_addr| ip_addr.include?(ip) }
  end

  def ip_whitelist
    @ips ||= Rails.application.config.ip_whitelist.map { |ip| IPAddr.new(ip) }
  end
end
