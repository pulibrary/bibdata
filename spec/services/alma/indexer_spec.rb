require 'rails_helper'

RSpec.describe Alma::Indexer do
  describe "#full_reindex" do
    it "gets the latest full dump tar, unzips it, and indexes all the containing files" do
      event = FactoryBot.create(:full_dump_event)
      binding.pry
    end
  end
end
