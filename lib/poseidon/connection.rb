# Connection
# =========
# 
# 用于处理连接的读写操作，由于Poseidon在协议解析上没有做太多的
# 工作，只支持基础的数据传输方式，比如分块传输就不支持，大多数
# 主流Ruby App Server都采用了C语言扩展来处理协议解析相关工作，
# 这里我们不会用到

module Poseidon
  
  class Connection

    attr_reader :client, :request_hash

    CRLF = "\r\n"

    def initialize(connection)
      @client = connection
      @request_hash = {}
      @get_sep_flag = false
      @remain_body_size = nil
      @response = nil
    end

    def ready_to_read?
      @remain_body_size != 0
    end

    def ready_to_write?
      @response.respond_to? :each
    end

    def ready_to_handle?
      @remain_body_size == 0 && @response.nil?
    end

    def request_raw
      return "" unless ready_to_handle?

      @request_hash["headers_raw"].to_s + CRLF + @request_hash["body_raw"].to_s
    end

    def request_body_raw
      return "" unless ready_to_handle?

      @request_hash["body_raw"].to_s
    end

    def response=(response)
      @response = response
      response_status, response_headers, response_body = *response

      _body = ""
      response_body.each { |msg| _body << msg }
      response_body.close if response_body.respond_to? :close

      @response_data = "HTTP/1.1 #{response_status}#{CRLF}" \
                       "Date: #{Time.now.httpdate}#{CRLF}" \
                       "Status: #{Rack::Utils::HTTP_STATUS_CODES[response_status]}#{CRLF}" \
                       "Connection: close#{CRLF}"

      response_headers.each do |k,v|
        @response_data << "#{k}: #{v}#{CRLF}"
      end
      @response_data << "#{CRLF}"
      @response_data << _body
    end

    def reset
      @request_hash.clear
      @get_sep_flag = false
      @remain_body_size = nil
      @response_data = nil
      @response = nil

      self
    end

    def readable!
      begin
        on_data
        nil
      rescue Errno::EAGAIN
      rescue IOError
        close
      end
    end

    def on_data
      @get_sep_flag ? read_body : read_header
    end

    def read_body
      return unless @get_sep_flag
      
      @request_hash["body_raw"] ||= ""
      data = _read_data(@client, :read_nonblock, @remain_body_size)
      @request_hash["body_raw"] << data.to_s
      @remain_body_size = @remain_body_size - data.bytesize
    end

    def read_header
      @request_hash["headers_raw"] ||= ""
      head_line = _read_data(@client, :gets, CRLF)
      if head_line == CRLF
        @get_sep_flag = true
        format_headers
      else
        @request_hash["headers_raw"] << head_line.to_s
      end
    end

    def format_headers
      return unless @get_sep_flag

      headers = @request_hash["headers_raw"].split(CRLF)

      @request_hash["request_line"] = headers.shift

      _method, = @request_hash["request_line"].split(" ")
      @request_hash["method"] = _method

      headers.each do |head_line|
        key, value = head_line.split(": ")
        @request_hash[key] = value
      end

      @remain_body_size = @request_hash["Content-Length"].to_i
    end

    def _read_data(io, method, *arg)
      io.__send__(method, *arg)
    end

    def writable!
      begin
        bytes = @client.write_nonblock @response_data
        @response_data.slice! 0, bytes
        @response_data.empty? ? close : nil
      rescue Errno::EAGAIN
      rescue IOError
        close
      end
    end

    def close
      _fileno = @client.fileno

      begin
        @client.close
      rescue IOError
      end

      _fileno
    end

  end

end
