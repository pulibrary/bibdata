require_relative 'queries'
require_relative 'oracle_connection'
require 'date'
require 'diffy'

module VoyagerHelpers
  class SyncFu
    class << self
      include VoyagerHelpers::Queries
      include VoyagerHelpers::OracleConnection

      def bib_ids_to_file(file_handle, conn=nil)
        query = VoyagerHelpers::Queries.all_unsupressed_bib_ids
        if conn.nil?
          connection do |c|
            exec_bib_ids_to_file(query, file_handle, c)
          end
        else
          exec_bib_ids_to_file(query, file_handle, conn)
        end
      end

      def compare_id_dumps(earlier_file, later_file, now=nil)
        now = DateTime.now.new_offset(0) if now.nil?
        diff = Diffy::Diff.new(earlier_file, later_file, source: 'files', context: 0)
        diff_hashes = diff_to_hash_array(diff)
        grouped_diffs = group_by_plusminus(diff_hashes)
        id_set = bib_id_set_from_diff(diff)
        grouped_diffs_to_cud_hash(grouped_diffs, id_set, now)
      end

      private

      def exec_bib_ids_to_file(query, file_handle, connection)
        File.open(file_handle, 'w') do |f|
          f.write("BIB_ID CREATE_DATE UPDATE_DATE\n")
          connection.exec(query) do |id, created, updated|
            f.write("#{id} #{created.to_datetime} #{updated.to_datetime unless updated.nil?}\n")
          end
        end
      end

      def parse_line_to_hash(line)
        parts = line.split(' ')
        hsh = {
          plusminus: parts[0][0], # + or -
          bib_id: parts[0][1..-1], # Strip + or -
          created: DateTime.parse(parts[1]).new_offset(0)
        }
        # Strip trailing \n
        hsh[:updated] = DateTime.parse(parts[2][0..-2]).new_offset(0) if parts[2]
        hsh
      end

      def diff_to_hash_array(diff)
        diff.to_a.map { |line| parse_line_to_hash(line) }
      end

      def bib_id_set_from_diff(diff)
        diff.to_a.map { |line| line.split(' ')[0][1..-1] }.uniq
      end

      def group_by_plusminus(diff_hashes)
        groups = {}
        grouped = diff_hashes.group_by { |h| h[:plusminus] }
        grouped.each do |key,val|
          groups[key] = {}
          val.map do |h|
            groups[key][h[:bib_id]] = h.select { |k,_| [:updated, :created].include? k }
          end
        end
        groups
      end

      def grouped_diffs_to_cud_hash(grouped_diffs, id_set, datetime)
        hsh = { create: [], update: [], delete: [] }
        id_set.each do |id|
          if grouped_diffs['-'].has_key?(id) && grouped_diffs['+'].has_key?(id)
            h = { id: id, datetime: grouped_diffs['+'][id][:updated] }
            hsh[:update] << h
          elsif grouped_diffs['+'].has_key?(id)
            h = { id: id }
            if grouped_diffs['+'][id].has_key?(:updated)
              h[:datetime] = grouped_diffs['+'][id][:updated]
            else
              h[:datetime] = grouped_diffs['+'][id][:created]
            end
            hsh[:create] << h
          else
            hsh[:delete] << { id: id, datetime: datetime }
          end
        end
        hsh.keys.each do |k|
          hsh[k] = hsh[k].sort_by { |h| h[:datetime] }
        end
        hsh
      end

    end # class << self
  end # class SyncFu
end # module VoyagerHelpers

