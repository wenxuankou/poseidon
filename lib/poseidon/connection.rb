module Poseidon
  
  class Connection

    attr_reader :client

    CRLF = "\r\n"
    CHUNK_SIZE = 1024 * 16

    def initialize(connection, app)
      @app = app
      @client = connection
      @protocol_parser = HttpParser.new
      @response = ""

      @request_line = nil
      @request_headers_raw = ""
      @request_headers = []
      @headers = {}

      @body = ""
      @remain_body_size = nil
    end

    def ready_to_read?
      true
    end

    def ready_to_write?
      !@response.empty?
    end

    def readable!
      begin
        on_data(_read_data(@client, :read_nonblock, @remain_body_size || CHUNK_SIZE))
        handle_request if @remain_body_size == 0
        nil
      rescue Errno::EAGAIN
      rescue IOError
        @client.fileno
      end
    end

    def _read_data(io, method, *arg)
      io.send(method.to_sym, *arg)
    end

    def on_data(data)
      return unless data

      if header_parsed? 
        # all data is http body
        @body << data
        @remain_body_size = @headers["Content-Length"].to_i - @body.bytesize
      else
        # data is http head and body
        _head, _body = data.split(/#{CRLF}{2,}/)
        @request_headers_raw = _head
        parse_headers!
        on_data(_body) if !_body.nil? && !_body.empty?
      end
    end

    def header_parsed?
      !!@request_line
    end

    def parse_headers!
      @request_headers = @request_headers_raw.split CRLF
      @request_line = @request_headers.shift
      @request_headers.each do |header|
        key, value = header.split(':')
        @headers[key.strip] = value.strip
      end
      @remain_body_size = @headers["Content-Length"].to_i
    end

    def handle_request
      @protocol_parser.parse nil, nil

      status, headers, body = @app.call nil

      head = 
        "HTTP/1.1 #{status}#{CRLF}" \
        "Date: #{Time.now.httpdate}#{CRLF}" \
        "Status: #{Rack::Utils::HTTP_STATUS_CODES[status]}#{CRLF}" \
        "Connection: close#{CRLF}"
      headers.each do |k,v|
        head << "#{k}: #{v}#{CRLF}"
      end
      @response << head << CRLF

      body.each { |b| @response << b }
      body.close if body.respond_to?(:close)
    end

    def writable!
      begin
        bytes = @client.write_nonblock @response
        @response.slice! 0, bytes
        @response.empty? ? close : nil
      rescue Errno::EAGAIN
      rescue IOError
        @client.fileno
      end
    end

    def close
      begin
        @client.close
      rescue IOError
      end

      @client.fileno
    end

  end

end
