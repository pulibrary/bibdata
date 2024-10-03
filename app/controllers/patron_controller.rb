class PatronController < ApplicationController
  before_action :protect

  attr_accessor :patron_id
  # Client: This endpoint is used by requests and orangelight for auth and by figgy
  #   to log patron types on CDL use
  def patron_info
    @patron_id = sanitize(params[:patron_id])
    info = parse_data
    info[:ldap] = Ldap.find_by_netid(patron_id) if params[:ldap].present? && sanitize(params[:ldap]) == "true"
    respond_to do |wants|
      wants.json  { render json: MultiJson.dump(info) }
    end
  rescue => e
    handle_alma_exception(exception: e, message: "Error fetching patron: #{@patron_id}")
  end

  private

    def sanitize(str)
      str.gsub(/[^A-Za-z0-9.]/, '')
    end

    def parse_data
      {
        netid:,
        first_name: data["first_name"],
        last_name: data["last_name"],
        barcode:,
        university_id: data["primary_id"],
        patron_id: data["primary_id"],
        patron_group:,
        patron_group_desc: data["user_group"]["desc"],
        active_email: primary_email
      }
    end

    def primary_email
      data["contact_info"]["email"].find do |email|
        email["preferred"] == true
      end&.fetch("email_address", nil)
    end

    def data
      @data ||= AlmaAdapter.new.find_user(patron_id)
    end

    def identifiers
      @identifiers ||= data["user_identifier"]
    end

    def barcode
      identifiers.find { |id| id["id_type"]["value"] == "BARCODE" && id["status"] == "ACTIVE" }["value"]
    end

    def netid
      identifier = identifiers.find { |id| id["id_type"]["value"] == "NET_ID" } || {}
      identifier["value"]
    end

    def patron_group
      data["user_group"]["value"]
    end

    def protect
      Rails.logger.info("Incoming patron request: IP is #{request.remote_ip}, User signed in is #{user_signed_in?}")
      if user_signed_in?
        deny_access unless current_user.catalog_admin?
      else
        ips = Rails.application.config.ip_allowlist
        Rails.logger.info("Is IP address excluded from the allow list?: #{ips.exclude?(request.remote_ip)}")
        if ips.exclude?(request.remote_ip)
          deny_access
          Rails.logger.info("Denied patron request: IP #{request.remote_ip} is not in the list: #{ips.join(', ')}")
          headers = {}.tap do |envs|
            request.headers.each do |key, value|
              envs[key] = value if key.downcase.starts_with?('http')
            end
          end
          Rails.logger.info("Headers of the request: #{headers}")
        end
      end
    end

    def deny_access
      render plain: "You are unauthorized", status: :forbidden
    end
end
