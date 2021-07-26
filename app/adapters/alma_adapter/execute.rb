class AlmaAdapter::Execute
  # Makes a call to the Alma gem using custom configuration options.
  #
  # @param options [Hash] custom configuration options to use for the Alma API call. Some
  # of the possible options are:
  #
  #   enable_loggable (boolean): True to request Alma to preserve the original exception
  #     to that we can handle PER_SECOND_THRESHOLD errors (otherwise we cannnot distinguish
  #     threshold errors from any other).
  #
  #   timeout (seconds): Used to allow longer requests than the default (5 seconds).
  #
  #   For a full list of options see https://github.com/tulibraries/alma_rb/blob/main/lib/alma/config.rb
  #
  # @param message [String] Message to include when logging the call.
  def self.call(options:, message:)
    # Saves the current values of the options to customize
    original = {}
    options.keys.each do |key|
      original[key] = Alma.configuration.send(key.to_s)
    end
    start = Time.now
    begin
      # Sets the new configuration values
      options.keys.each do |key|
        Alma.configure { |config| config.send(key.to_s + "=", options[key]) }
      end
      yield
    ensure
      # Restore the options to their original values
      options.keys.each do |key|
        Alma.configure { |config| config.send(key.to_s + "=", original[key]) }
      end
      log_elapsed(start, message)
    end
  end

  def self.log_elapsed(start, msg)
    elapsed_ms = ((Time.now - start) * 1000).to_i
    if elapsed_ms > 3000
      Rails.logger.warn("ELAPSED: #{msg} took #{elapsed_ms} ms")
    else
      Rails.logger.info("ELAPSED: #{msg} took #{elapsed_ms} ms")
    end
  end
end
