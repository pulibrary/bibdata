require 'rails_helper'

RSpec.describe CampusAccessException, type: :model do
  let(:uid) { 'user123' }

  context 'with out initail exceptions present' do
    let(:campus_exceptions) { described_class.new }
    it 'has no exceptions' do
      expect(campus_exceptions.current_exceptions).to eq([])
    end

    it 'exports and empty csv' do
      expect(campus_exceptions.export).to eq("full legal name - first - last,NetID issued by Princeton\n")
    end

    it 'processes new exceptions' do
      CampusAccess.create(uid: 'LEARN4', employee_id: '999999999', category: 'trained')
      additional_exceptions = Rails.root.join("spec", "fixtures", "library_access_request.xslx")
      campus_exceptions.process_new_exceptions(additional_exceptions)
      expect(campus_exceptions.export).to eq("full legal name - first - last,NetID issued by Princeton\nSally Smith,learn4\n")
      temp_file = Tempfile.new('campus_access')
      campus_exceptions.export_to_file(temp_file.path)
      temp_file.rewind
      expect(temp_file.read).to eq("full legal name - first - last,NetID issued by Princeton\nSally Smith,learn4\n")
      temp_file.unlink
      expect(campus_exceptions.invalid_exceptions).to eq(['999999998, John Doe'])
    end

    context "with Full CampusAccess present" do
      before do
        CampusAccess.create(uid: 'LEARN4', employee_id: '999999999')
      end

      it 'processes new exceptions' do
        additional_exceptions = Rails.root.join("spec", "fixtures", "library_access_request.xslx")
        campus_exceptions.process_new_exceptions(additional_exceptions)
        expect(campus_exceptions.export).to eq("full legal name - first - last,NetID issued by Princeton\n")
        expect(campus_exceptions.invalid_exceptions).to eq(['999999998, John Doe'])
      end
    end
  end

  context 'with exceptions present' do
    let(:csv_file) do
      csv_file = Tempfile.new('csv')
      csv_file.write("name,netid\nJill,j123\nJack,jj345")
      csv_file.close
      csv_file
    end

    let(:campus_exceptions) { described_class.new(csv_file.path, netid_key: 'netid') }

    after do
      csv_file.unlink
    end

    it 'has the specified exceptions' do
      expect(campus_exceptions.current_exceptions).to eq(['j123', 'jj345'])
    end

    it 'exports csv' do
      expect(campus_exceptions.export).to eq("name,netid\nJill,j123\nJack,jj345\n")
    end

    it 'processes new exceptions' do
      CampusAccess.create(uid: 'LEARN4', employee_id: '999999999', category: 'trained')
      additional_exceptions = Rails.root.join("spec", "fixtures", "library_access_request.xslx")
      campus_exceptions.process_new_exceptions(additional_exceptions)
      expect(campus_exceptions.export).to eq("name,netid\nJill,j123\nJack,jj345\nSally Smith,learn4\n")
      expect(campus_exceptions.invalid_exceptions).to eq(['999999998, John Doe'])
      temp_file = Tempfile.new('campus_access')
      campus_exceptions.export_to_file(temp_file.path)
      temp_file.rewind
      expect(temp_file.read).to eq("name,netid\nJill,j123\nJack,jj345\nSally Smith,learn4\n")
      temp_file.unlink
    end
  end
end
