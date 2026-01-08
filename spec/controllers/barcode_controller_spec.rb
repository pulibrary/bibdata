require 'rails_helper'
include FormattingConcern

RSpec.describe BarcodeController, type: :controller do
  describe '#scsb' do
    context 'when given a valid barcode' do
      it 'enriches a complex MARC with holdings and item info' do
        stub_alma_item_barcode(mms_id: '998574693506421', item_id: '23153444680006421', holding_id: '22153448500006421', barcode: '32101044947941')
        stub_sru('alma.mms_id=998574693506421',
                 '998574693506421')
        stub_alma_holding(mms_id: '998574693506421', holding_id: '22153448500006421')

        get :scsb, params: { barcode: '32101044947941' }, format: :xml

        expect(response).to be_successful
        record = MARC::XMLReader.new(StringIO.new(response.body)).first
        holding_id = '22153448500006421'
        expect(record['001'].value).to eq '998574693506421'
        # Ensure 852 fields come through
        expect(record['852']['0']).to eq holding_id
        expect(record['852']['b']).to eq 'recap$pn'
        expect(record['852']['c']).to eq 'pn'
        expect(record['852']['i']).to be_blank
        # Ensure 866 fields come through
        expect(record['866']['0']).to eq holding_id
        # Ensure 959 is correct (empty)
        expect(record['959']).to be_nil
        # Ensure there are no non-numeric fields
        # ReCAP's parser can't handle them.
        expect(record.fields.map { |x| format('%03d', x.tag.to_i) }).to contain_exactly(*record.fields.map(&:tag))
      end

      it "enriches a bound-with item with multiple bibs it's attached to" do
        stub_alma_item_barcode(mms_id: '99126768656906421', item_id: '23959387670006421', holding_id: '22639719450006421', barcode: '32101111979348')
        stub_sru('alma.mms_id=99126768656906421',
                 '99126768656906421')
        stub_alma_holding(mms_id: '99126768656906421', holding_id: '22639719450006421')
        stub_sru('alma.mms_tagSuppressed=false%20and%20alma.mms_id=996310183506421%20or%20alma.mms_id=996310063506421',
                 'constituents', 2)

        get :scsb, params: { barcode: '32101111979348' }, format: :xml

        expect(response).to be_successful
        records = MARC::XMLReader.new(StringIO.new(response.body)).to_a
        expect(records.length).to eq 2
        expect(records.map { |x| x['001'].value }).to eq %w[996310183506421 996310063506421]
        records.each do |record|
          expect(record['876']['z']).to eq 'PF'
          expect(record['852']['h']).to eq 'MICROFICHE 1138'
        end
      end

      it 'enriches the MARC record with holdings and item info' do
        stub_alma_item_barcode(mms_id: '9972625743506421', item_id: '2340957190006421', holding_id: '2240957220006421', barcode: '32101069559514')
        stub_sru('alma.mms_id=9972625743506421',
                 '9972625743506421')
        stub_alma_holding(mms_id: '9972625743506421', holding_id: '2240957220006421')

        voyager_comparison = MARC::XMLReader.new(File.open(Pathname.new(file_fixture_path).join('alma', 'comparison', 'voyager_scsb_32101069559514.xml'))).first
        get :scsb, params: { barcode: '32101069559514' }, format: :xml

        expect(response).to be_successful
        record = MARC::XMLReader.new(StringIO.new(response.body)).first
        expect(record['001'].value).to eq '9972625743506421'
        expect(record['876']['0']).to eq '2240957220006421' # Holding ID
        expect(record['876']['3']).to eq voyager_comparison['876']['3'] # enum_cron
        expect(record['876']['a']).to eq '2340957190006421' # Item ID
        expect(record['876']['p']).to eq '32101069559514' # Barcode
        expect(record['876']['t']).to eq voyager_comparison['876']['t'] # Copy Number
        expect(record['876']['j']).to eq 'Not Used'
        expect(record['876']['h']).to eq voyager_comparison['876']['h'] # ReCAP Use Restriciton
        expect(record['876']['x']).to eq voyager_comparison['876']['x'] # ReCAP Group Designation
        expect(record['876']['z']).to eq voyager_comparison['876']['z'] # ReCAP Customer Code
        expect(record['876']['l']).to eq 'RECAP'
        expect(record['876']['k']).to eq 'recap'
        expect(record['852']['h']).to eq voyager_comparison['852']['h']
        expect(record['852']['i']).to be_blank
      end

      it 'returns a 404 when the barcode is not found' do
        barcode = '32101108683143'
        alma_path = Pathname.new(file_fixture_path).join('alma')
        stub_request(:get, %r{.*\.exlibrisgroup\.com/almaws/v1/items.*})
          .with(query: { item_barcode: barcode })
          .to_return(status: 400,
                     headers: { 'Content-Type' => 'application/json' },
                     body: alma_path.join("barcode_#{barcode}.json"))

        get :scsb, params: { barcode: }, format: :xml

        expect(response).to be_not_found
      end
    end

    context 'when the bib record linked to a barcode is suppressed' do
      it 'returns a 200' do
        stub_alma_item_barcode(mms_id: '9958708973506421', item_id: '23178060180006421', holding_id: '22178060190006421', barcode: '32101076720315')
        stub_sru('alma.mms_id=9958708973506421', '9958708973506421')
        stub_alma_ids(ids: '9958708973506421', status: 200, fixture: '9958708973506421')
        stub_alma_holding(mms_id: '9958708973506421', holding_id: '22178060190006421')
        get :scsb, params: { barcode: '32101076720315' }, format: :xml

        expect(response).to be_successful
        record = MARC::XMLReader.new(StringIO.new(response.body)).first
        expect(record['001'].value).to eq '9958708973506421'
        expect(record['876']['0']).to eq '22178060190006421' # Holding ID
      end
    end

    context 'When Alma returns PER_THRESHOLD errors' do
      it 'handles error on items API call' do
        barcode = '32101076720316'
        stub_request(:get, %r{.*\.exlibrisgroup\.com/almaws/v1/items.*})
          .with(query: { item_barcode: barcode })
          .to_return(status: 429,
                     headers: { 'Content-Type' => 'application/json' },
                     body: stub_alma_per_second_threshold)
        get :scsb, params: { barcode: '32101076720316' }, format: :xml
        expect(response.status).to eq(429)
      end

      it 'handles error on holdings API call' do
        stub_alma_item_barcode(mms_id: '9972625743506421', item_id: '2340957190006421', holding_id: '2240957220006421', barcode: '32101069559514')
        stub_sru('alma.mms_id=9972625743506421',
                 '9972625743506421')
        stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9972625743506421/holdings/2240957220006421')
          .to_return(status: 429,
                     headers: { 'Content-Type' => 'application/json' },
                     body: stub_alma_per_second_threshold)
        get :scsb, params: { barcode: '32101069559514' }, format: :xml
        expect(response.status).to eq(429)
      end
    end
  end

  describe '#valid_barcode' do
    context 'barcode is valid' do
      let(:valid_barcode1) { '32101123456789' }
      let(:valid_barcode2) { 'PULTST12345' }

      it 'returns true' do
        expect(described_class.valid_barcode?(valid_barcode1)).to be(true)
        expect(described_class.valid_barcode?(valid_barcode2)).to be(true)
      end
    end

    context 'barcode is correct length but not valid' do
      let(:invalid_barcode_proper_length) { '31101123456789' }

      it 'returns false' do
        expect(described_class.valid_barcode?(invalid_barcode_proper_length)).to be(false)
      end
    end

    context 'barcode is not proper length' do
      let(:invalid_barcode_improper_length) { '321011234567890' }

      it 'returns false' do
        expect(described_class.valid_barcode?(invalid_barcode_improper_length)).to be(false)
      end
    end
  end
end
