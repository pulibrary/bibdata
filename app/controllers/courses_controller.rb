class CoursesController < ApplicationController
  def index
    @courses = VoyagerHelpers::Liberator.active_courses
    respond_to do |f|
      f.json do
        render json: MultiJson.dump(@courses)
      end
    end
  end

  def bibs
    @reserve_ids = params.fetch(:reserve_id)
    @bib_relations = VoyagerHelpers::Liberator.course_bibs(@reserve_ids)
    respond_to do |f|
      f.json do
        render json: MultiJson.dump(@bib_relations)
      end
    end
  end
end
