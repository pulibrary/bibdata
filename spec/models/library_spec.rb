# frozen_string_literal: true

require 'rails_helper'

describe Library, type: :model do
  subject { FactoryBot.create(:library) }

  describe 'validations' do
    it 'factory creates a valid instance' do
      library = FactoryBot.create(:library)
      expect(library.valid?).to be_truthy
    end

    %i[label code].each do |a|
      it "is not valid without a #{a}" do
        library = FactoryBot.create(:library)
        library.send("#{a}=", nil)
        expect(library.valid?).to be_falsey
      end
    end

    it 'code must be unique' do
      library = FactoryBot.create(:library)
      expect do
        FactoryBot.create(:library, code: library.code)
      end.to raise_error ActiveRecord::RecordInvalid
    end

    describe 'code must follow naming conventions' do
      it 'lets properly formed codes through' do
        expect do
          FactoryBot.create(:library, code: 'mycode42')
        end.not_to raise_error
      end

      it 'new is a valid code for friendly_id' do
        expect do
          FactoryBot.create(:library, code: 'new')
        end.not_to raise_error
      end

      it 'code can be 1 character' do
        expect do
          FactoryBot.create(:library, code: 'f')
        end.not_to raise_error
      end

      it 'code can be 14 characters' do
        expect do
          FactoryBot.create(:library, code: 'cotsenresearch')
        end.not_to raise_error
      end

      it 'may not be create' do
        expect do
          FactoryBot.create(:library, code: 'create')
        end.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
