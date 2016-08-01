require 'rails_helper'

RSpec.describe "Course Reserves", type: :request do
  describe "GET /courses.json" do
    it "returns JSON courses from VoyagerHelpers" do
      stub_all_courses

      get "/courses.json"

      expect(json_response).to eq [
        {
          "reserve_list_id" => 1958,
          "department_name" => "Molecular Biology",
          "department_code" => "MOL",
          "course_name" => "Genetics",
          "course_number" => "MOL 342",
          "section_id" => 171,
          "instructor_first_name" => "Gertrud M.",
          "instructor_last_name" => "Schupbach"
        }
      ]
    end
  end

  describe "GET /bib_ids?reserve_id[]=x" do
    it "returns all bib IDs with the given reserve ids" do
      stub_bib_ids

      get "/bib_ids?reserve_id[]=1&reserve_id[]=2"

      expect(json_response).to eq [
        {
          "reserve_list_id" => 1,
          "bib_id" => 3
        },
        {
          "reserve_list_id" => 2,
          "bib_id" => 4
        }
      ]
    end
  end

  def stub_all_courses
    allow(VoyagerHelpers::Liberator).to receive(:active_courses).and_return([
      VoyagerHelpers::Course.new(1958, "Molecular Biology", "MOL", "Genetics", "MOL 342", 171, "Gertrud M.", "Schupbach")
    ])
  end

  def stub_bib_ids
    allow(VoyagerHelpers::Liberator).to receive(:course_bibs).with([1, 2]).and_return([
      VoyagerHelpers::CourseBib.new(1,3),
      VoyagerHelpers::CourseBib.new(2,4)
    ])
  end

  def json_response
    JSON.parse(response.body)
  end
end
