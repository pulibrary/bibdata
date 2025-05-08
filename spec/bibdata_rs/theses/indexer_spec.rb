# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

module BibdataRs::Theses
  describe Indexer do
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

    let(:dspace) { subject.send(:dataspace) }
    let(:full_text) { subject.send(:full_text) }
    let(:citation) { subject.send(:citation) }


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

    describe '#_restrictions_display_text' do
      let(:indexer) { described_class.new }
      let(:solr_document) { indexer.build_solr_document(**attrs) }
      let(:values) { solr_document.to_solr }

      context 'when there is no embargo field' do
        let(:attrs) do
          {
            'id' => '123456'
          }
        end

        it 'returns nil for doc without embargo field' do
          expect(solr_document).to be_a(DataspaceDocument)
          expect(values).to be_a(Hash)
          expect(values).to include('restrictions_note_display')
          expect(values['restrictions_note_display']).to be_nil
        end
      end

      context 'when the resource is under embargo' do
        let(:attrs) do
          {
            'id' => '123456'
            # 'pu.embargo.lift' => ['2100-07-01']
          }
        end

        it 'returns valid formatted embargo date in restriction note' do
          expect(solr_document).to be_a(DataspaceDocument)
          expect(values).to be_a(Hash)
          expect(values).to include('restrictions_note_display')
          # expect(values['restrictions_note_display']).to include('July 1, 2100')
        end

        context 'when the access is restricted to walk-in patrons' do
          let(:attrs) do
            {
              'id' => '123456',
              'pu.embargo.lift' => ['2010-07-01'],
              'pu.mudd.walkin' => ['yes']
            }
          end

          it 'returns walk-in access note for lifted embargoes with walk-in property' do
            expect(solr_document).to be_a(DataspaceDocument)
            expect(values).to be_a(Hash)
            expect(values).to include('restrictions_note_display')
            # expect(values['restrictions_note_display']).to include('Walk-in Access.')
          end
        end

        context 'when there is an invalid embargo date' do
          let(:attrs) do
            {
              'id' => '123',
              'pu.embargo.lift' => ['never']
            }
          end

          it 'returns a message without the embargo date when the embargo date is invalid' do
            expect(solr_document).to be_a(DataspaceDocument)
            expect(values).to be_a(Hash)
            expect(values).to include('restrictions_note_display')
            # expect(values['restrictions_note_display']).to eq('This content is currently under embargo. For more information contact the <a href="mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/123"> Mudd Manuscript Library</a>.')
          end
        end

        context 'when the embargo date has passed' do
          let(:attrs) do
            {
              'id' => '123456',
              'pu.embargo.lift' => ['2010-07-01']
            }
          end

          it 'returns no restriction note' do
            expect(solr_document).to be_a(DataspaceDocument)
            expect(values).to be_a(Hash)
            expect(values).to include('restrictions_note_display')
            expect(values['restrictions_note_display']).to be_nil
          end
        end

        context 'when the access rights are restricted to walk-in patrons' do
          let(:attrs) do
            {
              'id' => '123',
              'pu.location' => ['restriction'],
              'pu.mudd.walkin' => ['yes']
            }
          end

          it 'generates a specific restriction note' do
            expect(solr_document).to be_a(DataspaceDocument)
            expect(values).to be_a(Hash)
            expect(values).to include('restrictions_note_display')
            # expect(values['restrictions_note_display']).to eq("Walk-in Access. This thesis can only be viewed on computer terminals at the '<a href=\"http://mudd.princeton.edu\">Mudd Manuscript Library</a>.")
          end
        end
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
      let(:h) { subject.send(:map_rest_non_special_to_solr, doc) }

      it 'adds the expected keys' do
        expect(h).to include('author_display' => doc['dc.contributor.author'])
        author_facet = [doc['dc.contributor.author'], doc['dc.contributor'],
                        doc['dc.contributor.advisor'], doc['pu.department']].flatten
        expect(h['author_s']).to match_array(author_facet)
        expect(h).to include('summary_note_display' => doc['dc.description.abstract'])
      end

      it 'but leaves others out' do
        expect(h).not_to have_key('id')
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

    describe '#_class_year_fields' do
      let(:class_year) { ['2014'] }
      let(:doc_int) { { 'pu.date.classyear' => class_year } }
      let(:doc_no_int) { { 'pu.date.classyear' => ['Undated'] } }
      let(:doc_no_field) { {} }

      it 'returns empty hash when no integer in classyear field' do
        expect(subject.send(:class_year_fields, doc_no_int)).to eq({})
      end

      it 'returns empty hash when no classyear field' do
        expect(subject.send(:class_year_fields, doc_no_field)).to eq({})
      end

      it 'returns hash with class year as value for year fields' do
        expect(subject.send(:class_year_fields, doc_int)['class_year_s']).to eq(class_year)
        expect(subject.send(:class_year_fields, doc_int)['pub_date_start_sort']).to eq(class_year)
        expect(subject.send(:class_year_fields, doc_int)['pub_date_end_sort']).to eq(class_year)
      end
    end

    describe '#_holdings_access' do
      let(:doc_restrictions) { doc }
      let(:doc_embargo) { doc.merge('pu.embargo.terms' => ['2100-01-01']) }
      let(:doc_no_restrictions) { {} }

      describe 'in the library' do
        it 'in the library access for record with restrictions note' do
          entries = subject.send(:holdings_access, doc_restrictions)
          expect(entries).to include('access_facet')
          result = entries['access_facet']
          expect(result).to eq('Online')
        end

        it 'includes mudd as an advanced location value' do
          result = subject.send(:holdings_access, doc_restrictions)
          expect(result).not_to include('advanced_location_s')
        end
      end

      describe 'embargo' do
        it 'in the library access for record with restrictions note' do
          expect(subject.send(:holdings_access, doc_embargo)['access_facet']).to be_nil
          entries = subject.send(:holdings_access, doc_embargo)
          expect(entries['access_facet']).to be_nil
        end

        it 'includes mudd as an advanced location value' do
          expect(subject.send(:holdings_access,
                              doc_embargo)['advanced_location_s']).to include('Mudd Manuscript Library')
        end
      end

      # Alma update
      describe 'online' do
        it 'online access for record without restrictions note' do
          expect(subject.send(:holdings_access, doc_no_restrictions)['access_facet']).to eq('Online')
        end

        it 'electronic portfolio field' do
          expect(subject.send(:holdings_access, doc_no_restrictions)['electronic_portfolio_s']).to include('thesis')
        end
      end
    end

    describe '#_code_to_language' do
      it 'defaults to English when no dc.language.iso field' do
        expect(subject.send(:code_to_language, nil)).to eq ['English']
      end

      it 'maps valid language code to standard language name' do
        expect(subject.send(:code_to_language, ['fr'])).to include 'French'
      end

      it 'supports multiple language codes' do
        expect(subject.send(:code_to_language, %w[el it])).to include('Greek, Modern (1453-)', 'Italian')
      end

      it 'dedups' do
        expect(subject.send(:code_to_language, %w[en_US en])).to eq ['English']
      end
    end
  end
end
