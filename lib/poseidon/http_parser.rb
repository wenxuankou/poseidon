# HttpParser
# =========
#
# HTTP解析器将原始的HTTP请求，解析成为能够传递给Rack应用的env对象。

module Poseidon

  class HttpParser

    CRLF = "\r\n"

    def initialize
    end

    # 解析器需要反复使用，所以需要有一个重置的方法
    def reset
      @request_raw = nil
      @env = {}

      self
    end
    
    def parse(data)
      @request_raw = data

      headers, body = @request_raw.split("#{CRLF}#{CRLF}")

      header_lines = headers.split CRLF

      # 设置请求行相关env数据
      set_request_info(header_lines.shift)

      header_hash = Hash.new
      header_lines.each do |line|
        key, value = line.split(": ")
        header_hash[key] = value
      end

      # 设置Host数据
      set_host_info(header_hash["Host"])
      # 设置其他http头
      set_http_variables(header_hash)

      @env
    end

    def set_request_info(request_line)
      _method, *path_and_version = request_line.split(" ")

      @env["SERVER_PROTOCOL"] = path_and_version.last

      _full_path = (path_and_version.count == 1 ? "" : path_and_version.first)

      path, query = _full_path.split("?")

      @env["REQUEST_METHOD"] = _method.upcase
      # This may be an empty string, if the application corresponds to the “root” of the server.
      @env["SCRIPT_NAME"] = '/'
      # if the request URL targets the application root and does not have a trailing slash. 
      # This value may be percent-encoded when originating from a URL.
      @env["PATH_INFO"] = path || '/'
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
    def set_http_variables(header_hash)
      header_hash.each do |key, value|
        key = key.split("-").join("_").upcase
        if "CONTENT_LENGTH" == key
          @env[key] = value.to_i
        elsif "CONTENT_TYPE" == key
          @env[key] = value
        else
          @env["HTTP_#{key}"] = value
        end
      end
    end
  end

end
