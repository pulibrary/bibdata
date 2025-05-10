# frozen_string_literal: true

require 'rails_helper'

describe 'BibdataRs::Theses::DataspaceDocument', :rust do
  subject(:dataspace_document) { BibdataRs::Theses::DataspaceDocument.new(document:, logger:) }

  let(:id) { 'test-id' }
  let(:logger) { instance_double(Logger) }

  describe '#to_solr' do
    let(:solr_document) { dataspace_document.to_solr }

    before do
      allow(logger).to receive(:warn)
    end

    context 'when there are dc.rights.accessRights' do
      let(:document) do
        {
          'id' => id,
          'dc.rights.accessRights' => 'Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>.'
        }
      end

      it 'logs a warning' do
        expect(solr_document).to be_a(Hash)
        expect(solr_document['restrictions_note_display']).to eq ["Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>."]
      end
    end
  end
end
