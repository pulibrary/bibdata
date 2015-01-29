require_relative 'queries'
require_relative 'oracle_connection'
require 'date'
require 'diffy'

module VoyagerHelpers
  class SyncFu
    class << self
      include VoyagerHelpers::Queries
      include VoyagerHelpers::OracleConnection
      # @param earlier_file [String]
      # @param later_file [String]
      #
      # Both files are formatted with a with a line per record consisting
      # of the record ID and the created and updated dates (as appropriate)
      # separated by ' ', e.g.:
      #
      #  ```
      #  3 2000-06-08T00:00:00-05:00 2010-06-16T15:55:32-05:00
      #  4 2000-06-08T00:00:00-05:00 2003-06-18T13:13:44-05:00
      #  5 2000-06-08T00:00:00-05:00 2011-05-04T10:14:46-05:00
      #  6 2000-06-08T00:00:00-05:00
      #  8 2000-06-08T00:00:00-05:00 2012-07-06T10:21:00-05:00
      #  ```
      #
      # These files can be obtained by calling #bib_ids_to_file or
      # #holding_ids_to_file
      # @return [ChangeReport]
      def compare_id_dumps(earlier_file, later_file, now=nil)
        now = DateTime.now.new_offset(0) if now.nil?
        diff = Diffy::Diff.new(earlier_file, later_file, source: 'files', context: 0)
        diff_hashes = diff_to_hash_array(diff)
        grouped_diffs = group_by_plusminus(diff_hashes)
        id_set = id_set_from_diff(diff)
        grouped_diffs_to_change_report(grouped_diffs, id_set, now)
      end

      def bib_ids_to_file(file_handle, conn=nil)
        query = VoyagerHelpers::Queries.all_unsupressed_bib_ids
        ids_to_file(file_handle, query, conn=nil)
      end

      def holding_ids_to_file(file_handle, conn=nil)
        query = VoyagerHelpers::Queries.all_unsupressed_mfhd_ids
        ids_to_file(file_handle, query, conn=nil)
      end

      private

      def ids_to_file(file_handle, query, conn=nil)
        if conn.nil?
          connection do |c|
            exec_ids_to_file(query, file_handle, c)
          end
        else
          exec_ids_to_file(query, file_handle, conn)
        end
      end

      def exec_ids_to_file(query, file_handle, connection)
        File.open(file_handle, 'w') do |f|
          connection.exec(query) do |id, created, updated|
            f.write("#{id} #{created.to_datetime unless created.nil?} #{updated.to_datetime unless updated.nil?}\n")
          end
        end
      end

      def parse_diff_line_to_hash(line)
        parts = line.split(' ')
        hsh = {
          plusminus: parts[0][0], # + or -
          id: parts[0][1..-1], # Strip + or -
          created: DateTime.parse(parts[1]).new_offset(0)
        }
        # Strip trailing \n
        hsh[:updated] = DateTime.parse(parts[2][0..-2]).new_offset(0) if parts[2]
        hsh
      end

      def diff_to_hash_array(diff)
        diff.to_a.map { |line| parse_diff_line_to_hash(line) }
      end

      def id_set_from_diff(diff)
        diff.to_a.map { |line| line.split(' ')[0][1..-1] }.uniq
      end

      def group_by_plusminus(diff_hashes)
        groups = {}
        grouped = diff_hashes.group_by { |h| h[:plusminus] }
        grouped.each do |key,val|
          groups[key] = {}
          val.map do |h|
            groups[key][h[:id]] = h.select { |k,_| [:updated, :created].include? k }
          end
        end
        groups
      end

      def grouped_diffs_to_change_report(grouped_diffs, id_set, datetime)
        report = ChangeReport.new
        id_set.each do |id|
          if grouped_diffs['-'].has_key?(id) && grouped_diffs['+'].has_key?(id)
            h = { id: id, lastmod: grouped_diffs['+'][id][:updated] }
            report.updated << h
          elsif grouped_diffs['+'].has_key?(id)
            h = { id: id }
            if grouped_diffs['+'][id].has_key?(:updated)
              h[:lastmod] = grouped_diffs['+'][id][:updated]
            else
              h[:lastmod] = grouped_diffs['+'][id][:created]
            end
            report.created << h
          else
            report.deleted << { id: id, lastmod: datetime }
          end
        end
        report
      end

    end # class << self
  end # class SyncFu


end # module VoyagerHelpers














