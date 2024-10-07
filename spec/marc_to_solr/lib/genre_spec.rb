require 'rails_helper'

RSpec.describe Genre do
  describe '#to_a' do
    let(:genres) do
      g600 = { "600" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "Exclude" }, { "v" => "John" }, { "x" => "Join" }] } }
      g630 = { "630" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "x" => "Fiction." }] } }
      g655 = { "655" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "Culture." }, { "x" => "Dramatic rendition" }, { "v" => "Awesome" }] } }
      g655_2 = { "655" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Poetry" }, { "x" => "Translations into French" }, { "v" => "Maps" }] } }
      g655_3 = { "655" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Manuscript" }, { "x" => "Translations into French" }, { "v" => "Genre" }, { "2" => "rbgenr" }] } }
      sample_marc = MARC::Record.new_from_hash('fields' => [g600, g630, g655, g655_2, g655_3])
      described_class.new(sample_marc).to_a
    end

    it 'trims punctuation' do
      expect(genres).to include("Culture")
    end

    it 'excludes $a when not 655' do
      expect(genres).not_to include("Exclude")
    end

    it 'excludes 2nd indicator of 7 if vocab type is not in approved list' do
      expect(genres).not_to include("Maps")
      expect(genres).not_to include("Poetry")
    end

    it 'includes 2nd indicator of 7 if vocab type is in approved list' do
      expect(genres).to include("Manuscript")
      expect(genres).to include("Genre")
    end

    it 'includes 6xx $v and 655 $a' do
      expect(genres).to include("John")
      expect(genres).to include("Awesome")
    end

    it 'includes 6xx $x from filtered in terms' do
      expect(genres).to include("Fiction")
    end

    it 'excludes $x terms that do not match filter list' do
      expect(genres).not_to include("Join")
      expect(genres).not_to include("Dramatic renditon")
    end
  end
end
