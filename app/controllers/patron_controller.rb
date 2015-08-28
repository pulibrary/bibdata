class PatronController < ApplicationController
  include FormattingConcern
  before_filter :protect

  def patron_info
    data = VoyagerHelpers::Liberator.get_patron_info(sanitize(params[:patron_id]))
    respond_to do |wants|
      wants.json  { render json: MultiJson.dump(data) }
    end
  end

  private
  def protect
    unless user_signed_in?
      @ips = load_ip_whitelist
      if not @ips.include? request.remote_ip
         render :text => "You are unauthorized", status: 404
      end
    end
  end

  def load_ip_whitelist
    YAML.load(File.open("./config/ip_whitelist.yml"))
  end
end