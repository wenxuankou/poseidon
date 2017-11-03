require 'test_helper'

class ConnectionTest < MiniTest::Test

  def setup
    @client = StringIO.new
    @connection = ::Poseidon::Connection.new(@client)
  end

  def ready_to_read_test
    # 默认可读
    @connection.reset
    assert(@connection.ready_to_read?)
    @connection.send(:instance_variable_set, "@remain_body_size", 0)
    # 如果剩余字节为0，则不可读
    refute(@connection.ready_to_read?)
  end

  def ready_to_write_test
    # 有rack提供的response对象存在，则可写，默认无response，不可写
    @connection.reset
    refute(@connection.ready_to_write?) 
    @connection.response = [200, {"Content-Length": "200"}, ["hello", "world"]]
    assert(@connection.ready_to_write?)
  end

  def ready_to_handle_test
    # 可读数据长度为0，且无response对象，表示应该进行逻辑处理
    @connection.reset
    refute(@connection.ready_to_handle?)
    @connection.send(:instance_variable_set, "@remain_body_size", 0)
    assert(@connection.ready_to_handle?)
  end

  def _read_data_test
    @connection.reset
    @client.write "hello\r\n"
    assert_equal "hello\r\n", @connection._read_data(@client, :gets, "\r\n")
    @client.write "world"
    assert_equal "world", @connection._read_data(@client, :read_nonblock, 5)
  end

end
