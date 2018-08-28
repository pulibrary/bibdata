class ArkResolver
  attr_reader :ark
  def initialize(ark:)
    @ark = ark
  end

  def location
    @location ||=
      begin
        return unless final_result && final_result.status == 302
        final_result.headers["location"]
      end
  end

  private

    def initial_result
      return unless ark.present?
      @initial_result ||= Faraday.head(ark)
    end

    def final_result
      return unless initial_result && initial_result.status == 301
      @final_result ||= Faraday.head(initial_result.headers["location"])
    end
end
