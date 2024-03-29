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
        described_class.create(uid:)
      end

      it 'finds a user with access' do
        expect(described_class.has_access?(uid)).to be_truthy
      end
    end

    context 'with a training record present' do
      let(:uid) { 'admin123' }
      before do
        described_class.create(uid:, category: 'trained')
      end

      it 'finds a user with access' do
        expect(described_class.has_access?(uid)).to be_falsey
      end
    end
  end

  describe '#to_csv' do
    before do
      described_class.create(uid: 'USER1')
      described_class.create(uid: 'user2')
      described_class.create(uid: 'user3', category: 'trained')
    end
    it 'creates a csv with only the full users' do
      expect(described_class.to_csv).to eq("user1@princeton.edu\nuser2@princeton.edu\n")
    end
  end

  describe "#load_access" do
    it "loads the database with the xslx, trained file and additional ids override while removing existing rows" do
      described_class.create(uid: 'abc123')
      f = File.expand_path("../../fixtures/access.xlsx", __FILE__)
      trained_file = File.expand_path("../../fixtures/access_learn.xlsx", __FILE__)
      described_class.load_access(f, trained_file:, additional_ids: ['learn4'])
      expect(described_class.count).to eq(8)
      expect(described_class.all.map { |access| [access.uid, access.category, access.employee_id] }).to contain_exactly(["test1", "full", '010001112'], ["test2", "full", '010001111'], ["test3", "full", '010001113'], ["test6", "full", '010001116'], ["test5", "full", '010001115'], ["learn1", "trained", '999999999'], ["learn2", "trained", '999999998'], ["learn4", "full", '999999996'])
    end

    it "loads the database with the xslx file and additional ids removing existing rows" do
      described_class.create(uid: 'abc123')
      f = File.expand_path("../../fixtures/access.xlsx", __FILE__)
      described_class.load_access(f, additional_ids: ['elephant1', 'dog2'])
      expect(described_class.count).to eq(7)
      expect(described_class.all.map(&:uid)).to contain_exactly("test1", "test2", "test3", "test5", "test6", 'elephant1', 'dog2')
    end

    it "leaves the database alone if the file does not exist and no ids are given" do
      described_class.create(uid: 'abc123')
      f = File.expand_path("../../fixtures/access2.xlsx", __FILE__)
      described_class.load_access(f)
      expect(described_class.count).to eq(1)
      expect(described_class.all.map(&:uid)).to contain_exactly("abc123")
    end

    it "loads additional is only if the file does not exist" do
      described_class.create(uid: 'abc123')
      f = File.expand_path("../../fixtures/access2.xlsx", __FILE__)
      described_class.load_access(f, additional_ids: ['elephant1', 'dog2'])
      expect(described_class.count).to eq(3)
      expect(described_class.all.map(&:uid)).to contain_exactly("abc123", 'elephant1', 'dog2')
    end
  end
end
