# Connection
# =========
# 
# 用于处理连接的读写操作，由于Poseidon在协议解析上没有做太多的
# 工作，只支持基础的数据传输方式，比如分块传输就不支持，大多数
# 主流Ruby App Server都采用了C语言扩展来处理协议解析相关工作

module Poseidon
  
  class Connection

    attr_reader :client, :request_hash

    CRLF = "\r\n"
    DEFAULT_READ_CHUNK_SIZE = 16 * 1024

    def initialize(connection, app)
      @client = connection
      @app = app

      @response = nil

      # 协议解析器
      @parser = ::Http::Parser.new(self)
    end

    def receive_data(data)
      @parser << data
    end

    def on_message_begin
      @headers = nil
      @body = ''
      @complete = false
    end

    def on_headers_complete(headers)
      @headers = headers
    end

    def on_body(chunk)
      @body << chunk
    end

    def on_message_complete
      @complete = true
    end

    def ready_to_read?
      !@complete
    end

    def ready_to_write?
      @response.respond_to? :each
    end

    def ready_to_handle?
      @complete && @response.nil?
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
      receive_data @client.read_nonblock(DEFAULT_READ_CHUNK_SIZE)
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

    def eval_rack_app
      return unless ready_to_handle?

      env = get_rack_env
      self.response = @app.call(rack_env_init.merge(env))
    end

		def rack_env_init
      env = { 
        'rack.input' => StringIO.new(@body.encode!(Encoding::ASCII_8BIT)),
        'rack.multithread' => false,
        'rack.multiprocess' => true,
        'rack.run_once' => false,
        'rack.errors' => $stderr,
        'rack.version' => [2, 0],
        'rack.url_scheme' => "http",
        'rack.hijack?' => false
      }
		end

    def get_rack_env
      @env = {}

      # 设置请求行相关env数据
      set_request_info(@headers)
      # 设置Host数据
      set_host_info(@headers["Host"])
      # 格式化http头
      format_http_variables(@headers)

      @env
    end

    def set_request_info(header_hash)
      @env["SERVER_PROTOCOL"] = 'HTTP/' + @parser.http_version.join('.')
      @env["REQUEST_METHOD"] = @parser.http_method
      # This may be an empty string, if the application corresponds to the “root” of the server.
      @env["SCRIPT_NAME"] = ''
      # if the request URL targets the application root and does not have a trailing slash. 
      # This value may be percent-encoded when originating from a URL.
      path_info, query = @parser.request_url.split('?')
      @env["PATH_INFO"] = path_info || ''
      # The portion of the request URL that follows the ?, if any. May be empty, but is always required!
      @env["QUERY_STRING"] = query || ''
    end

    def set_host_info(host)
      return unless host

      server, port = host.split ":"

      @env["SERVER_NAME"] = server || ""
      @env["SERVER_PORT"] = port || "80"
    end

    # Variables corresponding to the client-supplied HTTP request headers 
    # (i.e., variables whose names begin with HTTP_).
    def format_http_variables(header_hash)
      header_hash.each do |key, value|
        key = key.split("-").join("_").upcase
        if "CONTENT_LENGTH" == key
          @env[key] = value
        elsif "CONTENT_TYPE" == key
          @env[key] = value
        else
          @env["HTTP_#{key}"] = value
        end
      end
    end

  end

end
