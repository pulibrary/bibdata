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
            new_record.fields.concat(marc_record.fields)
            marc_record.fields.each do |field|
              new_record.append(field)
            end
            AlmaAdapter::MarcRecord.new(nil, new_record)
          end
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
