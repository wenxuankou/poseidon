require "test_helper"

class HttpParserTest < Minitest::Test

  def setup
    @parser = ::Poseidon::HttpParser.new
    @data = "GET /user/1?name=nick&age=20 HTTP/1.1\r\n" + 
      "Host: localhost:8088\r\n" + 
      "Cache-Control: no-cache\r\n\r\n"
  end

  def test_parse
    env = @parser.reset.parse @data
    assert_equal "GET", env["REQUEST_METHOD"]
    assert_equal "HTTP/1.1", env["SERVER_PROTOCOL"]
    assert_equal "", env["SCRIPT_NAME"]
    assert_equal "/user/1", env["PATH_INFO"]
    assert_equal "name=nick&age=20", env["QUERY_STRING"]
    assert_equal "localhost", env["SERVER_NAME"]
    assert_equal "8088", env["SERVER_PORT"]
    assert_equal "localhost:8088", env["HTTP_HOST"]
    assert_equal "no-cache", env["HTTP_CACHE_CONTROL"]
  end

end
