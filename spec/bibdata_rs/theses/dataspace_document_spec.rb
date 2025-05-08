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

    context 'when the pu.embargo.lift date is invalid' do
      let(:document) do
        {
          'id' => id,
          'pu.embargo.lift' => ['invalid']
        }
      end

      it 'logs a warning' do
        expect(solr_document).to be_a(Hash)
        expect(solr_document).to include('restrictions_note_display' => "This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/#{id}\"> Mudd Manuscript Library</a>.")
        expect(logger).to have_received(:warn).with('Failed to parse the embargo date for test-id')
      end
    end

    context 'when the pu.embargo.terms date is invalid' do
      let(:document) do
        {
          'id' => id,
          'pu.embargo.terms' => ['invalid']
        }
      end

      it 'logs a warning' do
        expect(solr_document).to be_a(Hash)
        expect(solr_document).to include('restrictions_note_display' => "This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/#{id}\"> Mudd Manuscript Library</a>.")
        expect(logger).to have_received(:warn).with('Failed to parse the embargo date for test-id')
      end
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
