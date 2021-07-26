class DeprecatedEndpointsController < ApplicationController
  def gone
    render plain: "Deprecated endpoint", status: :gone
  end
end
