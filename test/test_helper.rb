$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "bundler/setup"
require "poseidon"
require "minitest/autorun"

PORT = 8088
LOG = File.join('test', 'log', 'poseidon.log')
TEST_CONFIG_RU = 'test/test_config.ru'

warn "Poseidon output can be found in #{LOG}"

def start_server(args = {})
  string_args = args.map { |k, v| "--#{k}=#{v}" }

  cmd = "ruby bin/poseidon -c \"#{TEST_CONFIG_RU}\" -p#{PORT} #{string_args.join(' ')}"

  @pid = Process.spawn(cmd, :err => :out, :out => LOG)
  sleep 1
end

def stop_server
  Process.kill(:QUIT, @pid)
rescue Errno::ESRCH
end

describe "Poseidon" do 
  it "have a version number" do 
    Poseidon::VERSION.wont_be_nil
  end
end
