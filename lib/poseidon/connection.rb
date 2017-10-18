module Poseidon
  
  class Connection

    attr_reader :client

    def initialize(connection, protocol_parser)
      @client, @protocol_parser = connection, protocol_parser
      @request, @response = "", ""
    end

    def ready_to_read?
      true
    end

    def ready_to_write?
      !@response.empty?
    end

  end

end
