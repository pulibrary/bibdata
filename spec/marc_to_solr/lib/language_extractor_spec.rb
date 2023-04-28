# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LanguageExtractor do
  let(:fields) do
    [
      { '008' => '120627s2012    ncuabg  ob    001 0 gre d' }
    ]
  end
  let(:extractor) { described_class.new(MARC::Record.new_from_hash('fields' => fields)) }
  describe('#possible_language_subject_headings') do
    let(:fields) do
      [
        { '650' => { 'subfields' => [{ 'a' => 'Kootenai language' }, { 'v' => 'Texts' }] } }
      ]
    end
    it 'includes the subject heading from the 650$a if 650$v is Texts' do
      expect(extractor.possible_language_subject_headings).to contain_exactly('Kootenai language')
    end
  end
end
