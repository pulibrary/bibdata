# frozen_string_literal: true

require 'rails_helper'
require 'rexml/document'

module BibdataRs::Theses
  describe Indexer, :rust do
    def load_fixture(name)
      REXML::Document.new(File.new(fixture_path(name))).root
    end


    let(:fixture1) { REXML::Document.new(File.new(file_fixture('theses/dsp013t945q852.xml'))).root }

    let(:doc) do
      {
        'id' => 'dsp01b2773v788',
        'dc.description.abstract' => ['Summary'],
        'dc.contributor' => ['Wolff, Tamsen'],
        'dc.contributor.advisor' => ['Sandberg, Robert'],
        'dc.contributor.author' => ['Clark, Hillary'],
        'dc.date.accessioned' => ['2013-07-11T14:31:58Z'],
        'dc.date.available' => ['2013-07-11T14:31:58Z'],
        'dc.date.created' => ['2013-04-02'],
        'dc.date.issued' => ['2013-07-11'],
        'dc.identifier.uri' => ['http://arks.princeton.edu/ark:/88435/dsp01b2773v788'],
        'dc.format.extent' => ['102 pages'],
        'dc.language.iso' => ['en_US'],
        'dc.title' => ['Dysfunction: A Play in One Act'],
        'dc.type' => ['Princeton University Senior Theses'],
        'pu.date.classyear' => ['2014'],
        'pu.department' => ['Princeton University. Department of English', 'Princeton University. Program in Theater'],
        'pu.pdf.coverpage' => ['SeniorThesisCoverPage'],
        'dc.rights.accessRights' => ['Walk-in Access...']
      }
    end

    describe '#_map_rest_non_special_to_solr' do
      let(:h) { subject.build_solr_document(**doc).document }

      it 'adds the expected keys' do
        expect(h).to include('author_display' => doc['dc.contributor.author'])
        author_facet = [doc['dc.contributor.author'], doc['dc.contributor'],
                        doc['dc.contributor.advisor'], doc['pu.department']].flatten
        expect(h['author_s']).to match_array(author_facet)
        expect(h).to include('summary_note_display' => doc['dc.description.abstract'])
      end
    end

    describe 'format' do
      it 'is senior thesis' do
        expect(subject.build_solr_document(**{})['format']).to eq 'Senior thesis'
      end
    end

    describe '#_class_year_fields' do
      let(:class_year) { ['2014'] }
      let(:doc_int) { { 'pu.date.classyear' => class_year } }
      let(:doc_no_int) { { 'pu.date.classyear' => ['Undated'] } }
      let(:doc_no_field) { {} }

      it 'returns empty hash when no integer in classyear field' do
        expect(subject.build_solr_document(**doc_no_int)['class_year_s']).to be_nil
        expect(subject.build_solr_document(**doc_no_int)['pub_date_start_sort']).to be_nil
        expect(subject.build_solr_document(**doc_no_int)['pub_date_end_sort']).to be_nil
      end

      it 'returns empty hash when no classyear field' do
        expect(subject.build_solr_document(**doc_no_field)['class_year_s']).to be_nil
        expect(subject.build_solr_document(**doc_no_field)['pub_date_start_sort']).to be_nil
        expect(subject.build_solr_document(**doc_no_field)['pub_date_end_sort']).to be_nil
      end

      it 'returns hash with class year as value for year fields' do
        expect(subject.build_solr_document(**doc_int)['class_year_s']).to eq(class_year)
        expect(subject.build_solr_document(**doc_int)['pub_date_start_sort']).to eq(class_year)
        expect(subject.build_solr_document(**doc_int)['pub_date_end_sort']).to eq(class_year)
      end
    end

    describe '#_holdings_access' do
      let(:doc_restrictions) { doc }
      let(:doc_embargo) { doc.merge('pu.embargo.terms' => ['2100-01-01']) }
      let(:doc_no_restrictions) { {} }

      describe 'in the library' do
        it 'in the library access for record with restrictions note' do
          entries = subject.build_solr_document(**doc_restrictions).document
          expect(entries).to include('access_facet')
          result = entries['access_facet']
          expect(result).to eq('Online')
        end

        it 'does not have an advanced location value' do
          result = subject.build_solr_document(**doc_restrictions).document
          expect(result).not_to include('advanced_location_s')
        end
      end

      describe 'embargo' do
        it 'in the library access for record with restrictions note' do
          expect(subject.build_solr_document(**doc_embargo).document['access_facet']).to be_nil
        end

        it 'includes mudd as an advanced location value' do
          expect(subject.build_solr_document(**doc_embargo).document['advanced_location_s']).to include('Mudd Manuscript Library')
        end
      end

      # Alma update
      describe 'online' do
        it 'online access for record without restrictions note' do
          expect(subject.build_solr_document(**doc_no_restrictions).document['access_facet']).to eq('Online')
        end

        it 'electronic portfolio field' do
          expect(subject.build_solr_document(**doc_no_restrictions).document['electronic_portfolio_s']).to include('thesis')
        end
      end
    end
  end
end
