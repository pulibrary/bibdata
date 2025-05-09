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

    let(:dspace) { "DataSpace" }
    let(:full_text) { "Full text" }
    let(:citation) { "Citation only" }


    describe '#_on_site_only?' do
      let(:doc_embargo_terms) { { 'pu.embargo.terms' => ['2100-01-01'] } }
      let(:doc_embargo_lift) { { 'pu.embargo.lift' => ['2100-01-01'] } }
      let(:doc_embargo_lift_past) { { 'pu.embargo.lift' => ['2000-01-01'] } }
      let(:doc_past_embargo_walkin) { { 'pu.embargo.lift' => ['2000-01-01'], 'pu.mudd.walkin' => ['yes'] } }
      let(:doc_location) { { 'pu.location' => ['physical location'] } }
      let(:doc_restriction) { doc }
      let(:doc_nothing) { {} }

      it 'doc with embargo terms field returns true' do
        expect(subject.send(:on_site_only?, doc_embargo_terms)).to be true
      end

      it 'doc with embargo lift field returns true' do
        expect(subject.send(:on_site_only?, doc_embargo_lift)).to be true
      end

      it 'doc with expired embargo lift field returns false' do
        expect(subject.send(:on_site_only?, doc_embargo_lift_past)).to be false
      end

      context 'without a specified accession date' do
        it 'returns false' do
          result = subject.send(:on_site_only?, doc_past_embargo_walkin)
          expect(result).to be false
        end
      end

      context 'with a specified accession date prior to 2013' do
        let(:doc) { { 'pu.embargo.lift' => ['2000-01-01'], 'pu.mudd.walkin' => ['yes'], 'pu.date.classyear' => ['2012-01-01T00:00:00Z'] } }

        it 'returns true' do
          result = subject.send(:on_site_only?, doc)
          expect(result).to be true
        end
      end

      context 'with a specified accession date in 2013' do
        let(:doc) { { 'pu.embargo.lift' => ['2000-01-01'], 'pu.mudd.walkin' => ['yes'], 'pu.date.classyear' => ['2013-01-01T00:00:00Z'] } }

        it 'returns false' do
          result = subject.send(:on_site_only?, doc)
          expect(result).to be false
        end
      end

      it 'doc with location field returns true' do
        result = subject.send(:on_site_only?, doc_location)
        expect(result).to be false
      end

      it 'doc with restrictions field returns true' do
        result = subject.send(:on_site_only?, doc_restriction)
        expect(result).to be false
      end

      it 'doc with no access-related fields returns false' do
        expect(subject.send(:on_site_only?, doc_nothing)).to be false
      end
    end

    describe '#_call_number' do
      let(:doc_no_id) { nil }
      let(:doc_id) { ['123'] }

      it 'when other identifier not present returns AC102' do
        expect(subject.send(:call_number, doc_no_id)).to eq('AC102')
      end

      it 'when other identifier present appends id to AC102' do
        expect(subject.send(:call_number, doc_id)).to eq('AC102 123')
      end
    end

    describe '#_ark_hash' do
      let(:ark_doc_citation) { doc }
      let(:ark_doc_full_text) do
        doc.delete('dc.rights.accessRights')
        doc
      end
      let(:no_ark) do
        doc.delete('dc.identifier.uri')
        doc
      end

      it 'gets the ark with citation link display when restrictions' do
        expect(ark_doc_citation).to include('dc.identifier.uri')
        arks = ark_doc_citation['dc.identifier.uri']
        expect(arks.length).to eq(1)
        ark = arks.first
        expected = %({"#{ark}":["#{dspace}","#{full_text}"]})
        result = subject.send(:ark_hash, ark_doc_citation)
        expect(result).to eq(expected)
      end

      it 'gets the ark with full text link display when no restrctions' do
        ark = ark_doc_full_text['dc.identifier.uri'].first
        expected = %({"#{ark}":["#{dspace}","#{full_text}"]})
        expect(subject.send(:ark_hash, ark_doc_full_text)).to eq expected
      end

      it 'returns nil if there is not a ark' do
        expect(subject.send(:ark_hash, no_ark)).to be_nil
      end
    end

    describe 'LaTex normalization' do
      it 'strips out all non alpha-numeric in LaTex expressions' do
        latex = '2D \\(^{1}\\)H-\\(^{14}\\)N HSQC inverse-detection experiments'
        title_search = subject.send(:title_search_hash, [latex])
        expect(title_search).to include(latex)
        expect(title_search).to include('2D 1H-14N HSQC inverse-detection experiments')
      end
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


    describe '#_title_sort_hash' do
      let(:with_punct) { ['"Some quote" : Blah blah'] }
      let(:with_article) { ['A title : blah blah'] }
      let(:with_punct_and_article) { ['"A quote" : blah blah'] }
      let(:not_an_article) { ['thesis'] }

      it 'strips punctuation' do
        expected = 'somequoteblahblah'
        expect(subject.send(:title_sort_hash, with_punct)).to eq expected
      end

      it 'strips articles' do
        expected = 'titleblahblah'
        expect(subject.send(:title_sort_hash, with_article)).to eq expected
      end

      it 'strips punctuation and articles' do
        expected = 'quoteblahblah'
        expect(subject.send(:title_sort_hash, with_punct_and_article)).to eq expected
      end

      it 'leaves words that start with articles alone' do
        expected = 'thesis'
        expect(subject.send(:title_sort_hash, not_an_article)).to eq expected
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
