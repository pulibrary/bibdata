require 'open-uri'

class NumismaticsIndexer
  def self.full_index(solr_url:, progressbar: false)
    new(solr_connection: RSolr.connect(url: solr_url), progressbar: progressbar).full_index
  end

  attr_reader :solr_connection, :progressbar
  def initialize(solr_connection:, progressbar: false)
    @solr_connection = solr_connection
    @progressbar = progressbar
  end

  def full_index
    solr_documents.each_slice(500) do |docs|
      solr_connection.add(docs)
    rescue RSolr::Error::Http => e
      Rails.logger.warn("Failed to index batch, retrying individually, error was: #{e.class}: #{e.message.strip}")
      index_individually(docs)
    end
    solr_connection.commit
  end

  # index a batch of records one at a time, logging and continuing on error
  def index_individually(docs)
    docs.each do |doc|
      solr_connection.add(doc)
    rescue RSolr::Error::Http => e
      Rails.logger.warn("Failed to index individual record #{doc['id']}, error was: #{e.class}: #{e.message.strip}")
    end
  end

  def solr_documents
    json_response = PaginatingJsonResponse.new(url: search_url)
    pb = progressbar ? ProgressBar.create(total: json_response.total, format: "%a %e %P% Processed: %c from %C") : nil
    json_response.lazy.map do |json_record|
      pb&.increment
      json_record
    end
  end

  class NumismaticRecordPathBuilder
    attr_reader :result
    def initialize(result)
      @result = result
    end

    def path
      "#{MARC_LIBERATION_CONFIG['figgy_base_url']}/concern/numismatics/coins/#{id}/orangelight"
    end

    def id
      result["id"]
    end
  end

  class PaginatingJsonResponse
    include Enumerable
    attr_reader :url
    def initialize(url:)
      @url = url
    end

    def each
      response = Response.new(url: url, page: 1)
      loop do
        response.docs.each do |doc|
          json = json_for(doc)
          yield json_for(doc) if json
        end
        break unless (response = response.next_page)
      end
    end

    def json_for(doc)
      path = NumismaticRecordPathBuilder.new(doc).path
      JSON.parse(open(path).read)
    rescue OpenURI::HTTPError => e
      Rails.logger.warn("Failed to retrieve numismatics document from #{path}, http status #{e.message.strip}")
      nil
    end

    def total
      @total ||= Response.new(url: url, page: 1).total_count
    end

    class Response
      attr_reader :url, :page
      def initialize(url:, page:)
        @url = url
        @page = page
      end

      def docs
        response["docs"]
      end

      def response
        @response ||= JSON.parse(open("#{url}&page=#{page}").read.force_encoding('UTF-8'))["response"]
      end

      def next_page
        return nil unless response["pages"]["next_page"]
        Response.new(url: url, page: response["pages"]["next_page"])
      end

      def total_count
        response["pages"]["total_count"]
      end
    end
  end

  def search_url
    "#{MARC_LIBERATION_CONFIG['figgy_base_url']}/catalog.json?f%5Bhuman_readable_type_ssim%5D%5B%5D=Coin&f%5Bstate_ssim%5D%5B%5D=complete&f%5Bvisibility_ssim%5D%5B%5D=open&per_page=100&q="
  end
end
