require 'rails_helper'

RSpec.describe ScsbFullRecordsRequest do
  let(:email) { 'test@princeton.edu' }
  let(:records_request) { described_class.new(scsb_env, email) }
  let(:conn) { records_request.scsb_conn }

  before do
    stub_request(:get, "#{scsb_url}/dataDump/exportDataDump?collectionGroupIds=1,2,5,6&emailToAddress=test@princeton.edu&fetchType=10&imsDepositoryCodes=RECAP&institutionCodes=CUL&outputFormat=0&requestingInstitutionCode=PUL&transmissionType=0")
      .with(headers: { Accept: '*/*', 'Api-Key': 'TESTME' })
      .to_return(status: 200, body: 'Export process has started and we will send an email notification upon completion', headers: {})
  end

  context 'using the uat environment' do
    let(:scsb_env) { 'uat' }
    let(:scsb_url) { 'https://uat-recap.htcinc.com:9093' }

    it 'can be instantiated' do
      expect(records_request).to be
      expect(records_request.scsb_env).to eq('uat')
      expect(records_request.email).to eq('test@princeton.edu')
      expect(records_request.scsb_host).to eq(scsb_url)
    end

    it 'has a connection' do
      expect(conn).to be_instance_of(Faraday::Connection)
    end

    it 'builds a request' do
      expect(records_request.scsb_request('CUL')).to be_instance_of(Faraday::Response)
    end

    context 'requesting Harvard items' do
      before do
        stub_request(:get, "#{scsb_url}/dataDump/exportDataDump?collectionGroupIds=1,2,5,6&emailToAddress=test@princeton.edu&fetchType=10&imsDepositoryCodes=RECAP,HD&institutionCodes=HL&outputFormat=0&requestingInstitutionCode=PUL&transmissionType=0")
          .with(headers: { Accept: '*/*', 'Api-Key': 'TESTME' })
          .to_return(status: 200, body: 'Export process has started and we will send an email notification upon completion', headers: {})
      end

      it 'builds a request' do
        expect(records_request.scsb_request('HL')).to be_instance_of(Faraday::Response)
      end
    end
  end

  context 'using the production environment' do
    let(:scsb_env) { 'production' }
    let(:scsb_url) { 'https://scsb.recaplib.org:9093' }

    it 'can be instantiated' do
      expect(records_request).to be
      expect(records_request.scsb_env).to eq('production')
      expect(records_request.email).to eq('test@princeton.edu')
      expect(records_request.scsb_host).to eq(scsb_url)
    end

    it 'builds a request' do
      expect(records_request.scsb_request('CUL')).to be_instance_of(Faraday::Response)
    end
  end
end
