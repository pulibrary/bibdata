class AlmaAdapter
  # Acts as a wrapper for MARC records coming in from the incremental SCSB job.
  # Handles logic for converting that record, with enrichments, to the format
  # expected by SCSB's submitCollection.
  # (https://htcrecap.atlassian.net/wiki/spaces/RTG/pages/27692276/Ongoing+Accession+Submit+Collection+through+API)
  class ScsbDumpRecord
    attr_reader :marc_record

    # @param marc_record [MARC::Record] Parsed version of the job MARC record.
    def initialize(marc_record:)
      @marc_record = marc_record
    end

    # @return [MARC::Record] Record suitable for SCSB's submitCollection
    def transformed_record
      @transformed_record ||=
        begin
          alma_marc_record.delete_conflicting_holding_data!
          alma_marc_record.delete_conflicting_item_data!
          items.concat(items_from_host).each do |item|
            alma_marc_record.enrich_with_item(item)
          end
          holdings.concat(holdings_from_host).each do |holding|
            alma_marc_record.enrich_with_holding(holding)
          end
          alma_marc_record
        end
    end

    # @return [String] MMS ID of the record
    def id
      marc_record["001"].value
    end

    # Tests if the record is a constituent record in a boundwith
    # @return [Boolean]
    def constituent?
      return true if marc_record["773"]
      false
    end

    # Gets ids of a host record's constituent records from the 774 field.
    # @return [Array<String>] constituent records MMS IDs
    def constituent_ids
      marc_record.find_all { |f| f.tag == "774" }.map { |f| f["w"] }
    end

    # Retrieve a host's constituent records from Alma
    # @param skip_ids [Array<String>] MMS IDs of records not to fetch from Alma
    # @return [Array<AlmaAdapter::ScsbDumpRecord>]
    def constituent_records(skip_ids: [])
      if constituent_ids.present?
        records_from_cache(constituent_ids - skip_ids)
      else
        []
      end
    end

    # Tests if the record is a host record in a boundwith
    # @return [Boolean]
    def host?
      return true if marc_record["774"]
      false
    end

    # Gets id of a constituent record's host record from the 773 field.
    # TODO: More than one host?
    # @return [String] host record MMS ID
    def host_id
      marc_record.find { |f| f.tag == "773" }["w"]
    end

    # Retrieve a constituent's host record from Alma
    # @return [AlmaAdapter::ScsbDumpRecord]
    def host_record
      @host_record ||=
        begin
          records_from_cache([host_id]).first if host_id
        end
    end

    # Tests is a record is part of a boundwith
    # @return [Boolean]
    def boundwith?
      constituent? || host?
    end

    def cache
      CachedMarcRecord.find_or_create_by(bib_id: id).tap do |record|
        record.marc = marc_record.to_xml
        record.save
      end
    end

    # 852/866/867/868 fields which have a subfield "8" (holding_id)
    # are all copied from holdings. Create an array of faux
    # AlmaHoldings from them.
    def holdings
      holding_fields_by_id.map do |holding_id, fields|
        holding_record = MARC::Record.new
        holding_record.fields.concat(fields)
        AlmaAdapter::AlmaHolding.for({ "holding_id" => holding_id }, holding_record: holding_record, recap: true)
      end
    end

    # Converts 876 fields in enriched dump file to AlmaAdapter::AlmaItems to
    # properly enrich the marc record.
    def items
      marc_record.fields("876").map do |field|
        AlmaAdapter::AlmaItem.new(Alma::BibItem.new(item_hash_from_876(field)))
      end
    end

    private

      # Retrieve records by id from the local cache or from the Alma API.
      # @param ids [Array<String>] bibids
      # @return [Array<AlmaAdapter::ScsbDumpRecord>]
      def records_from_cache(ids)
        cached_records = CachedMarcRecord.where(bib_id: ids)
        cached_records = cached_records.map { |r| AlmaAdapter::ScsbDumpRecord.new(marc_record: r.parsed_record) }
        cached_ids = cached_records.map(&:id)
        non_cached_ids = ids - cached_ids

        # rubocop:disable Style/GuardClause
        if non_cached_ids.present?
          raise StandardError, cache_error_message(non_cached_ids)
        else
          cached_records
        end
        # rubocop:enable Style/GuardClause
      end

      def cache_error_message(ids)
        "Records with mmsids not found in the cache: #{ids.join(', ')}. " \
          "Create a set of the missing records in Alma, publish using the " \
          "DRDS ReCAP Records publishing profile, and load into the cache " \
          "using the `cache_file` rake task"
      end

      def alma_marc_record
        @alma_marc_record ||=
          begin
            new_record = MARC::Record.new
            new_record.leader = marc_record.leader
            new_record.fields.concat(marc_record.fields)
            AlmaAdapter::MarcRecord.new(nil, new_record)
          end
      end

      # This mapping is pulled from Alma's ReCAP publishing job item enhancement
      # page. The structure is as returned by the Alma API, if that structure
      # changes then fixing the BarcodeController for the new API response
      # for items should break tests for this appropriately.
      def item_hash_from_876(field)
        {
          "bib_data" => {
          },
          "holding_data" => {
            "holding_id" => field["0"]
          },
          "item_data" => {
            "barcode" => field["p"],
            "base_status" => {
              # "desc"=> "Item in place",
              "value" => field["j"]
            },
            "chronology_i" => field["4"],
            "creation_date" => field["d"],
            "enumeration_a" => field["3"],
            "library" => {
              "desc" => "",
              "value" => field["y"]
            },
            "location" => {
              "desc" => "",
              "value" => field["z"]
            },
            "pid" => field["a"]
          }
        }
      end

      def holding_fields_by_id
        holding_eligible_fields.group_by do |field|
          field["8"]
        end
      end

      def holding_eligible_fields
        marc_record.fields(["852", "866", "867", "868"]).select do |field|
          field["8"].present?
        end
      end

      def holdings_from_host
        return [] unless constituent? && host_record
        host_record.holdings
      end

      def items_from_host
        return [] unless constituent? && host_record
        host_record.items
      end
  end
end
