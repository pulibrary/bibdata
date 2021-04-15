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
          items.each do |item|
            alma_marc_record.enrich_with_item(item)
          end
          holdings.each do |holding|
            alma_marc_record.enrich_with_holding(holding)
          end
          alma_marc_record
        end
    end

    private

      def alma_marc_record
        @alma_marc_record ||=
          begin
            new_record = MARC::Record.new
            new_record.leader = marc_record.leader
            new_record.fields.concat(marc_record.fields)
            AlmaAdapter::MarcRecord.new(nil, new_record)
          end
      end

      # Converts 876 fields in enriched dump file to AlmaAdapter::AlmaItems to
      # properly enrich the marc record.
      def items
        marc_record.fields("876").map do |field|
          AlmaAdapter::AlmaItem.new(Alma::BibItem.new(item_hash_from_876(field)))
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

      # 852/866/867/868 fields which have a subfield "8" are all copied from
      # holdings. Create an array of faux AlmaHoldings from them.
      def holdings
        holding_fields_by_id.map do |holding_id, fields|
          holding_record = MARC::Record.new
          holding_record.fields.concat(fields)
          AlmaAdapter::AlmaHolding.for({ "holding_id" => holding_id }, holding_record: holding_record, recap: true)
        end
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
  end
end
