module Poseidon

  module Logger

    def error(msg)
      Config.stderr.puts log_prefix + "[ERROR] " + msg      
    end

    def warn(msg)
      Config.stderr.puts log_prefix + "[WARN] " + msg      
    end

    def info(msg)
      Config.stdout.puts log_prefix + "[INFO] " + msg      
    end

    def debug(msg)
      Config.stdout.puts log_prefix + "[DEBUG] " + msg      
    end

    def log_prefix
      "[#{Time.now.strftime("%F %T")}] [#{Process.pid}] [#{$0}] "
    end

    extend self

  end

end
