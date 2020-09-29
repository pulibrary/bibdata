require 'rails_helper'

RSpec.describe Ldap, type: :model do
  subject(:data) { described_class.find_by_netid('abc123', ldap_connection: ldap_connection) }
  let(:ldap_connection) { Net::LDAP.new }
  let(:valid_ldap_response) do
    [{ dn: ["uid=abc123,o=princeton university,c=us"], telephonenumber: ["111-222-3333"], edupersonaffiliation: ["member", "staff", "employee"], puhomedepartmentnumber: ["99999"], sn: ["Smith"],
       objectclass: ["inetorgperson", "organizationalPerson", "person", "top", "puPerson", "nsMessagingServerUser", "inetUser", "ipUser", "inetMailUser", "inetLocalMailRecipient", "nManagedPerson", "userPresenceProfile", "oblixorgperson", "oblixPersonPwdPolicy", "eduPerson", "posixAccount"],
       givenname: ["Sally"], uid: ["abc123"], displayname: ["Sally Smith"], ou: ["Library Information Technology"], pudisplayname: ["Smith, Sally"], edupersonprincipalname: ["abc123@princeton.edu"], pustatus: ["stf"], edupersonprimaryaffiliation: ["staff"], cn: ["Sally Smith"], universityid: ["999999999"],
       loginshell: ["/bin/no login"], mail: ["sally.smith@princeton.edu"], edupersonentitlement: ["urn:mace:dir:entitlement:common-lib-terms"], puinterofficeaddress: ["Firestone Library$Library Information Technology"], title: ["Staff, Library - Information Technology."], street: ["B-1H-1 Firestone Library"] }]
  end

  # rubocop:disable RSpec/ExampleLength
  describe '#find_by_netid' do
    it 'parses a valid ldap response' do
      allow(ldap_connection).to receive(:search).with(filter: Net::LDAP::Filter.eq("uid", 'abc123')).and_return(valid_ldap_response)
      expect(data[:netid]).to eq('abc123')
      expect(data[:department]).to eq('Library Information Technology')
      expect(data[:address]).to eq('Firestone Library$Library Information Technology')
      expect(data[:telephone]).to eq('111-222-3333')
      expect(data[:givenname]).to eq('Sally')
      expect(data[:surname]).to eq('Smith')
      expect(data[:email]).to eq('sally.smith@princeton.edu')
      expect(data[:status]).to eq('staff')
      expect(data[:pustatus]).to eq('stf')
      expect(data[:universityid]).to eq('999999999')
      expect(data[:title]).to eq('Staff, Library - Information Technology.')
    end
    # rubocop:enable RSpec/ExampleLength

    it 'returns a blank hash for an invalid ldap response' do
      allow(ldap_connection).to receive(:search).with(filter: Net::LDAP::Filter.eq("uid", 'abc123')).and_return([])
      expect(data).to be_blank
    end
  end
end
