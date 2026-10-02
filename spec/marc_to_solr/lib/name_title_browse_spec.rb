# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'name_title_browse_s' do
  let(:leader) { '1234567890' }

  def record(fields)
    MARC::Record.new_from_hash('fields' => fields, 'leader' => leader)
  end

  def browse(fields)
    indexer = IndexerService.build
    indexer.map_record(record(fields))['name_title_browse_s']
  end

  describe 'related works and "contains" added entries (700/710/711)' do
    context 'when a 700 has both $a and $t and a blank 2nd indicator (related work)' do
      it 'indexes the name+title keeping only the title portion of the hierarchy' do
        result = browse([{ '700' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Doe, Jane' }, { 't' => 'Wild in the streets' }] } }])
        expect(result).to contain_exactly('Doe, Jane Wild in the streets')
      end
    end

    context 'when 710 and 711 added entries have a blank 2nd indicator' do
      it 'indexes both the corporate and meeting related works' do
        result = browse([{ '710' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Corp Name,' }, { 't' => 'A report' }] } },
                         { '711' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Meet Name,' }, { 't' => 'A session' }] } }])
        expect(result).to contain_exactly('Corp Name, A report', 'Meet Name, A session')
      end
    end

    context 'when a 700 has 2nd indicator "2" (contains)' do
      it 'indexes the name+title as a "contains" entry' do
        result = browse([{ '700' => { 'ind1' => '1', 'ind2' => '2', 'subfields' => [{ 'a' => 'Smith, John' }, { 't' => 'Contains title' }] } }])
        expect(result).to contain_exactly('Smith, John Contains title')
      end
    end

    context 'when 710 and 711 have 2nd indicator "2" (contains)' do
      it 'indexes both as "contains" entries' do
        result = browse([{ '710' => { 'ind1' => '2', 'ind2' => '2', 'subfields' => [{ 'a' => 'Corp2,' }, { 't' => 'Contained' }] } },
                         { '711' => { 'ind1' => '2', 'ind2' => '2', 'subfields' => [{ 'a' => 'Meet2,' }, { 't' => 'MeetingContained' }] } }])
        expect(result).to contain_exactly('Corp2, Contained', 'Meet2, MeetingContained')
      end
    end

    context 'when a 700 has 2nd indicator "1" (neither related nor contains)' do
      it 'does not index the entry at all' do
        result = browse([{ '700' => { 'ind1' => '1', 'ind2' => '1', 'subfields' => [{ 'a' => 'Foo, Bar' }, { 't' => 'Ignored title' }] } }])
        expect(result).to be_nil
      end
    end

    context 'when a 700 has $a but no $t' do
      it 'drops the entry, because a title is required' do
        result = browse([{ '700' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Doe, Jane' }, { 'd' => '1900' }] } }])
        expect(result).to be_nil
      end
    end

    context 'when a 700 carries a sub-heading hierarchy ($b before $t, $n after $t)' do
      it 'indexes each level of the title portion' do
        result = browse([{ '700' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Author, A' }, { 'b' => 'B' }, { 't' => 'Title One' }, { 'n' => 'part' }] } }])
        expect(result).to contain_exactly('Author, A B Title One', 'Author, A B Title One part')
      end
    end

    context 'when a related work and a "contains" entry are both present' do
      it 'indexes both, independently of their indicator' do
        result = browse([{ '700' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Rel, Name,' }, { 't' => 'Rel title' }] } },
                         { '710' => { 'ind1' => '2', 'ind2' => '2', 'subfields' => [{ 'a' => 'Cont, Corp,' }, { 't' => 'Cont title' }] } }])
        expect(result).to contain_exactly('Rel, Name, Rel title', 'Cont, Corp, Cont title')
      end
    end

    context 'when there are no 7xx added entries' do
      it 'does not contribute anything to the browse field' do
        # A title-only record, with no added entries and no primary author.
        result = browse([{ '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Just a title' }] } }])
        expect(result).to be_nil
      end
    end
  end

  describe 'analytical / added entries (800/810/811)' do
    context 'when a personal name 800 carries a full hierarchy' do
      it 'indexes the complete name-title hierarchy, including the name' do
        result = browse([{ '800' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Poe, Edgar Allan' }, { 'b' => 'Jr.' }, { 't' => 'Tales' }, { 'n' => '1' }] } }])
        expect(result).to contain_exactly('Poe, Edgar Allan Jr.', 'Poe, Edgar Allan Jr. Tales', 'Poe, Edgar Allan Jr. Tales 1')
      end
    end

    context 'when a corporate name 810 is present' do
      it 'indexes the corporate name-title hierarchy' do
        result = browse([{ '810' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Univ.' }, { 'b' => 'Lib.' }, { 't' => 'Reports' }] } }])
        expect(result).to contain_exactly('Univ. Lib', 'Univ. Lib. Reports')
      end
    end

    context 'when a simple meeting name 811 is present' do
      it 'indexes the name-only and the full name-title' do
        result = browse([{ '811' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Congress' }, { 't' => 'Papers' }] } }])
        expect(result).to contain_exactly('Congress', 'Congress Papers')
      end
    end

    context 'when a meeting name 811 carries sub-headings ($n, $d, $c before $t)' do
      it 'indexes each accumulated level of the hierarchy' do
        # A record about the 11th congress on nutrition -- a lovely interdisciplinary gathering.
        result = browse([{ '811' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Congress of Nutrition' }, { 'n' => '11th' }, { 'd' => '1978' }, { 'c' => 'Rio' }, { 't' => 'Proceedings' }] } }])
        expect(result).to contain_exactly('Congress of Nutrition 11th 1978 Rio', 'Congress of Nutrition 11th 1978 Rio Proceedings')
      end
    end

    context 'when a 800 is duplicated' do
      it 'de-duplicates the identical hierarchy values' do
        fields = [{ '800' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Dup, Author,' }, { 't' => 'Same title' }] } },
                  { '800' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Dup, Author,' }, { 't' => 'Same title' }] } }]
        result = browse(fields)
        expect(result).to contain_exactly('Dup, Author', 'Dup, Author, Same title')
      end
    end
  end

  describe 'linkage entries (76x/77x/78x)' do
    context 'when a 765 has both $a and $t' do
      it 'joins $a and $t' do
        # A related-work linkage: "Both name and title".
        result = browse([{ '765' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Both' }, { 't' => 'name and title' }] } }])
        expect(result).to contain_exactly('Both name and title')
      end
    end

    context 'when several linkage fields are present, some incomplete' do
      it 'keeps only the fields that have both $a and $t' do
        fields = [{ '765' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Both' }, { 't' => 'name and title' }] } },
                  { '770' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 't' => 'OnlyTitle' }] } }, # $t only -> dropped
                  { '780' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'OnlyName' }] } }, # $a only -> dropped
                  { '762' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Micro' }, { 't' => 'Form title' }] } }]
        result = browse(fields)
        expect(result).to contain_exactly('Both name and title', 'Micro Form title')
      end
    end

    context 'when a linkage field has neither $a nor $t' do
      it 'contributes nothing' do
        result = browse([{ '760' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'b' => 'only an edition' }] } }])
        expect(result).to be_nil
      end
    end
  end

  describe 'primary author 100/110/111 combined with a uniform 240 or 245$a' do
    context 'when a 100 is present with a 240 uniform title' do
      it 'prepends the author and indexes the uniform title hierarchy' do
        result = browse([{ '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Author, Name,' }] } },
                         { '240' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Uniform Title,' }, { 'p' => '5' }] } }])
        expect(result).to contain_exactly('Author, Name. Uniform Title', 'Author, Name. Uniform Title, 5')
      end
    end

    context 'when a 100, a 240, and also a 245 are present' do
      it 'prefers the 240 uniform title and ignores the 245' do
        result = browse([{ '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Author, X,' }] } },
                         { '240' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Uniform,' }] } },
                         { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Should be ignored' }] } }])
        expect(result).to contain_exactly('Author, X. Uniform')
      end
    end

    context 'when a 100 is present but neither a 240 nor a 245' do
      it 'does not index the author on its own' do
        result = browse([{ '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Lone, Author,' }] } }])
        expect(result).to be_nil
      end
    end

    context 'when a 100 is present with a 245$a but no uniform 240' do
      it 'joins the author with the 245 title' do
        result = browse([{ '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'García, Luz,' }] } },
                         { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Recipes for Sunday' }] } }])
        expect(result).to contain_exactly('García, Luz. Recipes for Sunday')
      end
    end

    context 'when a corporate author 110 is present with a 245$a' do
      it 'joins the corporate author with the 245 title' do
        result = browse([{ '110' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'United States,' }, { 'b' => 'Dept.' }] } },
                         { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Report title' }] } }])
        expect(result).to contain_exactly('United States, Dept. Report title')
      end
    end

    context 'when a meeting author 111 is present with a 240' do
      it 'joins the meeting author with the uniform title' do
        result = browse([{ '111' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Congress of Nutrition' }, { 'n' => '11th' }] } },
                         { '240' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Proceedings of Nutrition' }] } }])
        expect(result).to contain_exactly('Congress of Nutrition 11th. Proceedings of Nutrition')
      end
    end

    context 'when a 100 carries a $q fuller form of the name' do
      it 'includes the fuller form of the name' do
        result = browse([{ '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Fowler, T. M.' }, { 'q' => '(Thaddeus)' }, { 'd' => '1842' }] } },
                         { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Essays' }] } }])
        expect(result).to contain_exactly('Fowler, T. M. (Thaddeus) 1842. Essays')
      end
    end

    context 'when multiple 100/110/111 authors are present' do
      it 'uses only the first author for the combined entry' do
        fields = [{ '110' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Corp,' }] } },
                  { '111' => { 'ind1' => '2', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Meeting,' }] } },
                  { '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Main, Author,' }] } },
                  { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Some Title' }] } }]
        result = browse(fields)
        expect(result).to contain_exactly('Corp. Some Title')
      end
    end
  end

  describe 'parallel 880 "alternate script" versions of 100/240/245' do
    # rubocop:disable RSpec/IndexedLet
    let(:n100) { { '100' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'Name,' }] } } }
    let(:n100_vern) { { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '100-01' }, { 'a' => 'AltName ;' }] } } }
    let(:t240) { { '240' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-02' }, { 'a' => 'Uniform Title,' }, { 'p' => '5' }] } } }
    let(:t240_vern) { { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '240-02' }, { 'a' => 'AltUniform Title,' }, { 'p' => '5' }] } } }
    let(:t245) { { '245' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-03' }, { 'a' => 'Title 245a' }] } } }
    let(:t245_vern) { { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '245-03' }, { 'a' => 'VernTitle 245a' }] } } }
    # rubocop:enable RSpec/IndexedLet

    context 'when a uniform 240 is present for both scripts' do
      it 'indexes both scripts and ignores the 245' do
        result = browse([n100, n100_vern, t240, t240_vern, t245, t245_vern])
        expect(result).to contain_exactly('Name. Uniform Title', 'Name. Uniform Title, 5', 'AltName. AltUniform Title', 'AltName. AltUniform Title, 5')
      end
    end

    context 'when a 245 is present but no uniform 240' do
      it 'uses the 245 title for both scripts' do
        result = browse([n100, n100_vern, t245, t245_vern])
        expect(result).to contain_exactly('Name. Title 245a', 'AltName. VernTitle 245a')
      end
    end

    context 'when an 880 exists for the 100 but there is no 880 uniform title or 100-attached 245' do
      it 'does not index the vernacular author on its own' do
        result = browse([{ '100' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'Latin Name' }] } },
                         { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '100-01' }, { 'a' => 'Cyrillic Name' }] } }])
        expect(result).to be_nil
      end
    end

    context 'with a real Arabic author and uniform title (880 alternate script)' do
      it 'indexes the Latin and the Arabic variants' do
        fields = [{ '100' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'أحمد, الطاهري' }] } },
                  { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '100-01' }, { 'a' => 'Ahmad, Al-Tahri' }] } },
                  { '240' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ '6' => '880-02' }, { 'a' => 'الوصفة' }, { 'p' => '1' }] } },
                  { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '240-02' }, { 'a' => 'Recipe' }, { 'p' => '1' }] } }]
        result = browse(fields)
        expect(result).to contain_exactly('أحمد, الطاهري. الوصفة', 'أحمد, الطاهري. الوصفة 1', 'Ahmad, Al-Tahri. Recipe', 'Ahmad, Al-Tahri. Recipe 1')
      end
    end

    context 'with a Cyrillic author and a 245 alternate script' do
      it 'indexes the Cyrillic and Latin variants' do
        fields = [{ '100' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'Николай, Чибисов' }] } },
                  { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '100-01' }, { 'a' => 'Nikolai, Chibisov' }] } },
                  { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ '6' => '880-02' }, { 'a' => 'Дневник' }] } },
                  { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '245-02' }, { 'a' => 'Diary, Vol. 5' }] } }]
        result = browse(fields)
        expect(result).to contain_exactly('Николай, Чибисов. Дневник', 'Nikolai, Chibisov. Diary, Vol. 5')
      end
    end

    context 'with Chinese characters in the Romanized 100 $a (no vernacular title)' do
      it 'indexes the non-Latin name in the Latin field with the Latin title' do
        fields = [{ '100' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-01' }, { 'a' => '李白' }] } },
                  { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '100-01' }, { 'a' => 'Li Bai' }] } },
                  { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Poems about the full moon' }] } }]
        result = browse(fields)
        expect(result).to contain_exactly('李白. Poems about the full moon')
      end
    end
  end

  describe 'a record exercising many browse components at once' do
    it 'combines related, contains, linkage, analytical, and author-title entries' do
      fields = [{ '700' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Rel, Name,' }, { 't' => 'Rel title' }] } },
                { '710' => { 'ind1' => '2', 'ind2' => '2', 'subfields' => [{ 'a' => 'Cont, Corp,' }, { 't' => 'Cont title' }] } },
                { '765' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Link' }, { 't' => 'linked title' }] } },
                { '800' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'AE, Author,' }, { 't' => 'AE title' }] } },
                { '100' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '880-01' }, { 'a' => 'María, Chef' }] } },
                { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '100-01' }, { 'a' => 'أحمد الطاهري' }] } },
                { '240' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ '6' => '880-02' }, { 'a' => 'Uniform, Latin' }] } },
                { '880' => { 'ind1' => '', 'ind2' => ' ', 'subfields' => [{ '6' => '240-02' }, { 'a' => 'المثالي' }] } },
                { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Recipe for Tacos' }] } }]
      result = browse(fields)
      expect(result).to contain_exactly(
        'AE, Author',
        'AE, Author, AE title',
        'Link linked title',
        'Rel, Name, Rel title',
        'Cont, Corp, Cont title',
        'María, Chef. Uniform, Latin',
        'أحمد الطاهري. المثالي'
      )
    end
  end
end
