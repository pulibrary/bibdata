module VoyagerHelpers
  module OracleConnection


    def connection(opts={})
      conn = OCI8.new(
        VoyagerHelpers.config.du_user,
        VoyagerHelpers.config.db_password,
        VoyagerHelpers.config.db_name
      )
      yield conn
    ensure
      conn.logoff unless conn.nil?
    end

  end # module Connection
end # module VoyagerHelpers



