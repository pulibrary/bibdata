# Class for Traject indexing job
class IndexJob < ActiveJob::Base
  queue_as :default
  after_perform :after_cleanup
  attr_reader :pid, :output, :errors, :status

  # Perform the job
  # @param traject [String]
  # @param config [String]
  # @param file [String]
  # @param url [String]
  # @param commit [String]
  def perform(traject:, config:, file:, url:, commit:)
    @traject = traject
    @config = config
    @file = file
    @url = url
    @commit = commit

    execute!
  end

  private

    # Invoked after the job has finished
    # Reads from the output and error streams for the process
    # Also reads the exit status for the shell command invocation
    def after_cleanup
      @output = @output_stream.read
      @output_stream.close

      @errors = @errors_stream.read
      @errors_stream.close

      @status = @thread.value
    end

    # Generates the arguments for the traject invocation
    # @return [Array<String>]
    def opts
      ['--conf', @config, '--solr', @url, @commit, @file]
    end

    # Generates the command for the shell
    # @return [String]
    def cmd
      segments = [@traject] + opts
      segments.join(' ')
    end

    # Executes the command by piping the command to the shell
    def execute!
      _stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
      @thread = wait_thr
      @output_stream = stdout
      @errors_stream = stderr

      @pid = @thread.pid
    end
end
