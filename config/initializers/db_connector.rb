require_relative './constants'

module DB
  module Connector
    extend self

    def establish_connection
      ActiveRecord::Base.establish_connection(config)
    end

    def config
      DB_CONFIG
    end
  end
end

DB::Connector.establish_connection
