require 'spec_helper'

RSpec.describe Genre do
  describe '#to_a' do
    let(:genres) do
      g600 = { '600' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'Exclude' }, { 'v' => 'John' }, { 'x' => 'Join' }] } }
      g630 = { '630' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'x' => 'Fiction.' }] } }
      g655 = { '655' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'Culture.' }, { 'x' => 'Dramatic rendition' }, { 'v' => 'Awesome' }] } }
      g655_2 = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Poetry' }, { 'x' => 'Translations into French' }, { 'v' => 'Maps' }] } }
      g655_3 = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Manuscript' }, { 'x' => 'Translations into French' }, { 'v' => 'Genre' }, { '2' => 'rbgenr' }] } }
      sample_marc = MARC::Record.new_from_hash('fields' => [g600, g630, g655, g655_2, g655_3])
      described_class.new(sample_marc).to_a
    end

    it 'trims punctuation' do
      expect(genres).to include('Culture')
    end

    it 'excludes $a when not 655' do
      expect(genres).not_to include('Exclude')
    end

    it 'excludes 2nd indicator of 7 if vocab type is not in approved list' do
      expect(genres).not_to include('Maps')
      expect(genres).not_to include('Poetry')
    end

    it 'includes 2nd indicator of 7 if vocab type is in approved list' do
      expect(genres).to include('Manuscript')
      expect(genres).to include('Genre')
    end

    it 'includes 6xx $v and 655 $a' do
      expect(genres).to include('John')
      expect(genres).to include('Awesome')
    end

    it 'includes 6xx $x from filtered in terms' do
      expect(genres).to include('Fiction')
    end

    it 'excludes $x terms that do not match filter list' do
      expect(genres).not_to include('Join')
      expect(genres).not_to include('Dramatic renditon')
    end

    it 'defaults to not including Primary source' do
      expect(genres).not_to include('Primary source')
    end

    context 'when the 650 subfield x has Correspondence' do
      let(:genres) do
        g650 = { '650' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'Authors' }, { 'x' => 'Correspondence' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g650])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when the 600 subfield x has Notebooks, sketchbooks, etc.' do
      let(:genres) do
        g600 = { '600' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Magallanes, Alejandro' }, { 'x' => 'Notebooks, sketchbooks, etc.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g600])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when there is an extra space after the period "etc. "' do
      let(:genres) do
        g600 = { '600' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Magallanes, Alejandro' }, { 'x' => 'Notebooks, sketchbooks, etc. ' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g600])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when the 650 subfield v has Pamphlets' do
      let(:genres) do
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Franco-Prussian War, 1870-1871' }, { 'v' => 'Pamphlets.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g650])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when the 650 subfield v has Personal narratives' do
      let(:genres) do
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'World War, 1939-1945' }, { 'v' => 'Personal narratives.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g650])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary Sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when the 650 subfield v has Personal narratives, Italian.' do
      let(:genres) do
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'World War, 1939-1945' }, { 'v' => 'Personal narratives, Italian.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g650])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary Sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when the 650 subfield v has Pamphlets, and the 008 says it is a novel' do
      let(:genres) do
        g008 = { '008' => 'f'.rjust(34) } # f = Novel when it is in the 33rd position
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Franco-Prussian War, 1870-1871' }, { 'v' => 'Pamphlets.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g008, g650], 'leader' => '04137cam a2200853Ii 4500')
        described_class.new(sample_marc).to_a
      end

      it 'does not include Primary sources in the list of genres' do
        expect(genres).not_to include('Primary sources')
      end
    end

    context 'when the 650 subfield v has Pamphlets, and the 008 says it is non-fiction' do
      let(:genres) do
        g008 = { '008' => '0'.rjust(34) } # 0 = Nonfiction when it is in the 33rd position
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Franco-Prussian War, 1870-1871' }, { 'v' => 'Pamphlets.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g008, g650], 'leader' => '04137cam a2200853Ii 4500')
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when the 651 subfield x has Pictorial works' do
      let(:genres) do
        g651 = { '651' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Iran' }, { 'x' => 'Description and travel' }, { 'y' => '20th century' }, { 'x' => 'Pictorial works.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g651])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary sources in the list of genres' do
        expect(genres).to include('Primary sources')
      end
    end

    context 'when the 650 subfield x has Computer network resources' do
      let(:genres) do
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Dating (Social customs)' }, { 'x' => 'Computer network resources.' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g650])
        described_class.new(sample_marc).to_a
      end

      it 'does not include Primary sources in the list of genres' do
        expect(genres).not_to include('Primary sources')
      end
    end

    context 'when the 650 subfield a is Biography' do
      let(:genres) do
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Biography' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g650])
        described_class.new(sample_marc).to_a
      end

      it 'does not include Primary source' do
        expect(genres).not_to include('Primary sources')
      end
    end

    context 'when the 650 subfield a is Biography and the 600 and 100 match' do
      let(:genres) do
        g100 = { '100' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Wheaton, Wil,' }, { 'e' => 'author' }] } }
        g600 = { '600' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Wheaton, Wil.' }] } }
        g650 = { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Biography' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g100, g600, g650])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary source' do
        expect(genres).to include 'Primary sources'
      end
    end

    context 'when the 651 subfield v is Biography' do
      let(:genres) do
        g651 = { '651' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'New York (N.Y.)' }, { 'v' => 'Biography' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g651])
        described_class.new(sample_marc).to_a
      end

      it 'does not include Primary source' do
        expect(genres).not_to include('Primary sources')
      end
    end

    context 'when the 651 subfield v is Biography, and the 600 and 100 match' do
      let(:genres) do
        g100 = { '100' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Gornick, Vivian.' }, { '0' => 'http://id.loc.gov/authorities/names/n83057391' }] } }
        g600 = { '600' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Gornick, Vivian.' }] } }
        g651 = { '651' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'New York (N.Y.)' }, { 'v' => 'Biography' }] } }
        sample_marc = MARC::Record.new_from_hash('fields' => [g100, g600, g651])
        described_class.new(sample_marc).to_a
      end

      it 'includes Primary source' do
        expect(genres).to contain_exactly 'Primary sources', 'Biography'
      end
    end
  end
end
