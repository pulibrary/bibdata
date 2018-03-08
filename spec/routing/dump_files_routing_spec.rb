require "rails_helper"

RSpec.describe DumpFilesController, type: :routing do
  describe "routing" do

    # it "routes to #index" do
    #   expect(:get => "/dump_files").to route_to("dump_files#index")
    # end

    # it "routes to #new" do
    #   expect(:get => "/dump_files/new").to route_to("dump_files#new")
    # end

    it "routes to #show" do
      expect(get: "/dump_files/1").to route_to("dump_files#show", id: "1")
    end

    # it "routes to #edit" do
    #   expect(:get => "/dump_files/1/edit").to route_to("dump_files#edit", :id => "1")
    # end

    # it "routes to #create" do
    #   expect(:post => "/dump_files").to route_to("dump_files#create")
    # end

    # it "routes to #update" do
    #   expect(:put => "/dump_files/1").to route_to("dump_files#update", :id => "1")
    # end

    # it "routes to #destroy" do
    #   expect(:delete => "/dump_files/1").to route_to("dump_files#destroy", :id => "1")
    # end

  end
end
