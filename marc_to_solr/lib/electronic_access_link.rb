require_relative 'normal_uri_factory'
require_relative 'uri_ark'

class ElectronicAccessLink
  attr_reader :bib_id, :holding_id, :url_key, :z_label, :anchor_text

  # Constructor
  # @param bib_id Bib record ID for an electronic holding referencing the linked resource
  # @param holding_id Holding record ID for an electronic holding referencing the linked resource
  # @param url_key the URL for the resource serving as a key
  # @param z_label the label for the resource link
  # @param anchor_text the text for the link markup (<a> element)
  def initialize(bib_id:, holding_id:, url_key:, z_label:, anchor_text:, logger: Logger.new(STDOUT))
    @bib_id = bib_id
    @holding_id = holding_id
    @url_key = url_key
    @z_label = z_label
    @anchor_text = anchor_text
    @logger = logger
    process_url_key!
  end

  # Clones a new instance of the ElectronicAccessLink
  # @param link_args arguments which override the attributes for this instance
  # @return [ElectronicAccessLink]
  def clone(link_args)
    default_link_args = { bib_id: @bib_id, holding_id: @holding_id, url_key: @url_key, z_label: @z_label, anchor_text: @anchor_text }
    new_link_args = default_link_args.merge link_args
    self.class.new(**new_link_args)
  end
  alias dup clone

  # Generates the URL from the string URL key
  # @return [URI::Generic]
  def url
    return unless @url_key
    return @url if @url

    if @url_key.valid_encoding?
      @url_key = normal_url.to_s
      if !@url_key&.match?(URI::DEFAULT_PARSER.make_regexp)
        @logger.error "#{@bib_id} - invalid URL for 856$u value: #{@url_key}"
        @url_key = nil
      elsif @url_key.start_with?(%r{http:/[A-Za-z]})
        # Misleading URL "http:/" instead of "http://"
        @logger.error "#{@bib_id} - invalid URL for 856$u value (http:/): #{@url_key}"
        @url_key = nil
      else
        @url = URI.parse(@url_key)
      end
    else
      @logger.error "#{@bib_id} - invalid character encoding for 856$u value (invalid bytes replaced by *): #{@url_key.scrub('*')}"
      @url_key = nil
    end
  rescue URI::InvalidURIError
    @logger.error "#{@bib_id} - invalid URL for 856$u value: #{@url_key}"
    @url_key = nil
  end

  # Generates the ARK from the string URL key
  # @return [URI::ARK]
  def ark
    # If the URL is a valid ARK...
    return unless ark_class.princeton_ark? url: url

    # Cast the URL into an ARK
    @ark ||= ark_class.parse url:
  end

  # Generates the labels for the link markup
  # @return [Array<String>]
  def url_labels
    return @url_labels if @url_labels

    # Build the URL
    url_labels = [@anchor_text] # anchor text is first element
    url_labels << @z_label if @z_label # optional 2nd element if z
    @url_labels = url_labels
  end

  private

    # Accesses the Class used for URL normalization
    # @return [Class]
    def url_normalizer_factory_klass
      NormalUriFactory
    end

    # Constructs or accesses an instance of the URL normalizer
    # @return [NormalUriFactory]
    def url_normalizer_factory
      @url_normalizer ||= url_normalizer_factory_klass.new(value: @url_key)
    end

    # Constructs or accesses the normalized URL
    # @return [URI::Generic]
    def normal_url
      @normal_url ||= url_normalizer_factory.build
    end

    # Accesses the Class used for modeling ARKs
    # @return [Class]
    def ark_class
      URI::ARK
    end

    # Updates the object state based upon the url_key value
    def process_url_key!
      return unless @url_key

      # If a valid URL was extracted from the MARC metadata...
      return unless url&.host

      @anchor_text = url.host if @anchor_text.blank?
    end
end
