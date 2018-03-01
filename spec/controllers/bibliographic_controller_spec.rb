require 'rails_helper'

RSpec.describe BibliographicController, type: :controller do
  let(:bib_id) { '1234567' }
  let(:bib_record) { instance_double(MARC::Record) }
  let(:bib_record_xml) { File.read(Rails.root.join('spec', 'fixtures', "#{bib_id}.mrx")) }

  before do
    allow(bib_record).to receive(:to_xml).and_return bib_record_xml
    allow(VoyagerHelpers::Liberator).to receive(:get_bib_record).and_return bib_record
  end

  describe '#update' do
    it 'enqueues an Index Job for a bib. record using a bib. ID' do
      post :update, params: { bib_id: bib_id }
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end

    context 'when authenticated as an administrator' do
      login_admin

      it 'enqueues an Index Job for a bib. record using a bib. ID' do
        post :update, params: { bib_id: bib_id }
        expect(response).to redirect_to(index_path)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Reindexing job scheduled for #{bib_id}"
      end
    end
  end
end
