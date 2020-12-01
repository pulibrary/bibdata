class CodesController < ApplicationController
  include FormattingConcern

  def locations
    # TODO: Re-enable. Disabled as we no longer have VoyagerHelpers.
    # data = VoyagerHelpers::Liberator.get_locations
    # respond_to do |wants|
    #   wants.json  { render json: MultiJson.dump(data) }
    #   wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
    # end
  end
end
