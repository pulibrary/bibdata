class PatronController < ApplicationController
  before_filter :protect

  def patron_info
    data = VoyagerHelpers::Liberator.get_patron_info(sanitize(params[:patron_id]))
    if data.blank?
      render text: {}, status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(data) }
      end
    end
  end

  def patron_codes
    data = VoyagerHelpers::Liberator.get_patron_stat_codes(sanitize(params[:patron_id]))
    if data.blank?
      render text: {}, status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(data) }
      end
    end
  end

  private
  def protect
    unless user_signed_in?
      @ips = load_ip_whitelist
      if not @ips.include? request.remote_ip
         render text: "You are unauthorized", status: 403
      end
    end
  end

  def load_ip_whitelist
    YAML.load(File.open("./config/ip_whitelist.yml"))
  end
end
