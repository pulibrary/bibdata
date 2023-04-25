# frozen_string_literal: true

module AlmaApiLimitPatch
  # Overriding to access the response headers and check remaining API requests
  def get_bibs(ids, args = {})
    response = HTTParty.get(
      bibs_base_path,
      query: { mms_id: ids_from_array(ids) }.merge(args),
      headers:,
      timeout:
    )
    raise StandardError, get_body_from(response) unless response.code == 200

    check_api_limit(response)
    Alma::BibSet.new(get_body_from(response))
  end

  private

    def check_api_limit(response)
      remaining_requests = response.headers['x-exl-api-remaining'].to_i
      Honeybadger.notify("Approaching Alma API limit, #{remaining_requests} requests remaining") if remaining_requests < 150000
    end
end

Alma::Bib.singleton_class.prepend(AlmaApiLimitPatch)
