class PatronController < ApplicationController
  before_action :protect

  def patron_info
    patron_id = sanitize(params[:patron_id])
    data = Alma::User.find(patron_id)
    info = parse_data(data)
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

  def patron_codes
    # TODO: Re-enable. Disabled as we no longer have VoyagerHelpers.
    # data = VoyagerHelpers::Liberator.get_patron_stat_codes(sanitize(params[:patron_id]))
    # if data.blank?
    #   render json: {}, status: 404
    # else
    #   respond_to do |wants|
    #     wants.json  { render json: MultiJson.dump(data) }
    #   end
    # end
  end

  private

    def parse_data(data)
      {
        netid: data["user_title"]["value"], # TODO: change once netids are in an id field
        first_name: data["first_name"],
        last_name: data["last_name"],
        barcode: data["user_identifier"].select { |id| id["id_type"]["value"] == "BARCODE" && id["status"] == "ACTIVE" }.first["value"],
        university_id: data["primary_id"],
        patron_id: data["primary_id"],
        patron_group: data["user_group"]["value"] == "P" ? "staff" : data["user_group"]["value"],
        patron_group_desc: data["user_group"]["desc"]
      }
    end

    def protect
      unless user_signed_in?
        ips = Rails.application.config.ip_allowlist
        render plain: "You are unauthorized", status: 403 if not ips.include? request.remote_ip
      end
    end
end
