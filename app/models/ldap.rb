require 'net/ldap'

class Ldap
  class << self
    def find_by_netid(net_id, ldap_connection: default_connection)
      filter = Net::LDAP::Filter.eq("uid", net_id)
      result = ldap_connection.search(filter: filter).first
      return {} if result.blank?
      attributes(result)
    end

    private

      def attributes(result)
        {
          netid: result[:uid]&.first,
          department: result[:purescollege]&.first || result[:ou]&.first,
          address: result[:puinterofficeaddress]&.first,
          telephone: result[:telephonenumber]&.first,
          givenname: result[:givenname]&.first,
          surname: result[:sn]&.first,
          email: result[:mail]&.first,
          status: result[:edupersonprimaryaffiliation]&.first,
          pustatus: result[:pustatus]&.first,
          universityid: result[:universityid]&.first,
          title: result[:title]&.first
        }
      end

      def default_connection
        @default_connection ||= Net::LDAP.new host: "ldap.princeton.edu", base: "o=Princeton University,c=US", port: 636,
                                              encryption: {
                                                method: :simple_tls,
                                                tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
                                              }
      end
  end
end
