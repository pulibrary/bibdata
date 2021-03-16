class PatronController < ApplicationController
  before_action :protect

  attr_accessor :patron_id
  def patron_info
    @patron_id = sanitize(params[:patron_id])
    info = parse_data
    patron_access = CampusAccess.where(uid: patron_id).first || CampusAccess.new(uid: patron_id, category: "none")
    info[:campus_authorized] = patron_access.access?
    info[:campus_authorized_category] = patron_access.category
    info[:ldap] = Ldap.find_by_netid(patron_id) if params[:ldap].present? && sanitize(params[:ldap]) == "true"
    respond_to do |wants|
      wants.json  { render json: MultiJson.dump(info) }
    end
  rescue Alma::User::ResponseError
    render json: {}, status: 404
  end

  private

    def parse_data
      {
        netid: netid,
        first_name: data["first_name"],
        last_name: data["last_name"],
        barcode: barcode,
        university_id: data["primary_id"],
        patron_id: data["primary_id"],
        patron_group: patron_group,
        patron_group_desc: data["user_group"]["desc"],
        requests_total: data["requests"]["value"],
        loans_total: data["loans"]["value"],
        fees_total: data["fees"]["value"]
      }
    end

    def data
      @data ||= Alma::User.find(patron_id)
    end

    def identifiers
      @identifiers ||= data["user_identifier"]
    end

    def barcode
      identifiers.find { |id| id["id_type"]["value"] == "BARCODE" && id["status"] == "ACTIVE" }["value"]
    end

    def netid
      identifier = identifiers.find { |id| id["id_type"]["value"] == "NET_ID" }
      identifier["value"]
    end

    def patron_group
      val = data["user_group"]["value"]
      return "staff" if val == "P"
      val
    end

    def protect
      unless user_signed_in?
        ips = Rails.application.config.ip_allowlist
        render plain: "You are unauthorized", status: 403 if not ips.include? request.remote_ip
      end
    end
end
