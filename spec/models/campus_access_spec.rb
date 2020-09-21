require 'rails_helper'

RSpec.describe CampusAccess, type: :model do
  let(:uid) { 'user123' }

  describe '#has_access?' do
    it 'does not find a user without access' do
      expect(described_class.has_access?(uid)).to be_falsey
    end

    context 'with an record present' do
      let(:uid) { 'admin123' }
      before do
        described_class.create(uid: uid)
      end

      it 'finds a user with access' do
        expect(described_class.has_access?(uid)).to be_truthy
      end
    end
  end

  describe '#to_csv' do
    before do
      described_class.create(uid: 'USER1')
      described_class.create(uid: 'user2')
    end
    it 'creates a csv' do
      expect(described_class.to_csv).to eq("user1@princeton.edu\nuser2@princeton.edu\n")
    end
  end

  describe "#load_access" do
    it "loads the database with the xslx file removing existing rows" do
      CampusAccess.create(uid: 'abc123')
      f=File.expand_path("../../fixtures/access.xlsx",__FILE__)
      described_class.load_access(f)
      expect(CampusAccess.count).to eq(4)
      expect(CampusAccess.all.map(&:uid)).to contain_exactly("test1", "test2", "test3", "test6")
    end

    it "leaves the database alone if the file does not exist" do
      CampusAccess.create(uid: 'abc123')
      f=File.expand_path("../../fixtures/access2.xlsx",__FILE__)
      described_class.load_access(f)
      expect(CampusAccess.count).to eq(1)
      expect(CampusAccess.all.map(&:uid)).to contain_exactly("abc123")
    end
  end
end
