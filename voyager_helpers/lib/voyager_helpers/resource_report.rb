module VoyagerHelpers
  class ResourceReport
    attr_accessor :resources

    # @param file_handle [String] A files are formatted with a with a line per
    # record consisting of the record ID and the created and updated dates
    # (as appropriate), separated by ' ', e.g.:
    #
    #  ```
    #  3 2000-06-08T00:00:00-05:00 2010-06-16T15:55:32-05:00
    #  4 2000-06-08T00:00:00-05:00 2003-06-18T13:13:44-05:00
    #  5 2000-06-08T00:00:00-05:00 2011-05-04T10:14:46-05:00
    #  6 2000-06-08T00:00:00-05:00
    #  8 2000-06-08T00:00:00-05:00 2012-07-06T10:21:00-05:00
    #  ```
    def initialize(file_handle)
      self.resources = []
      init_from_file(file_handle)
    end

    private

    def init_from_file(fh)
      IO.foreach(fh) do |line|
        puts line
        self.resources << self.class.parse_line_to_hash(line)
      end
    end

    def self.parse_line_to_hash(line)
      parts = line.split(' ')
      hsh = {
        id: parts[0],
        created: DateTime.parse(parts[1]).new_offset(0)
      }
      # Strip trailing \n
      hsh[:updated] = DateTime.parse(parts[2][0..-2]).new_offset(0) if parts[2]
      hsh
    end

    class << self
      private
    end # class << self

  end # class ResourceReport
end # module VoyagerHelpers
