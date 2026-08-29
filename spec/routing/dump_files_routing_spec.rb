require 'rails_helper'

RSpec.describe DumpFilesController, type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/dump_files/1').to route_to('dump_files#show', id: '1')
    end
  end
end
