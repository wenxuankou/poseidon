module Poseidon

  class Monitor

    include Singleton

    def start(sockets)
      trap_signals

      $PROGRAM_NAME = "poseidon-monitor"

      Socket.accept_loop(sockets) do |connection|
        @master_pid = fork do

          $PROGRAM_NAME = "poseidon-master"

          Master.new(connection, sockets).start
        end

        connection.close

        Process.waitpid @master_pid
      end
    end

    def trap_signals
      [:QUIT, :INT].each do |signal|
        trap(signal) do 
          begin
            Process.kill(signal, @master_pid) if @master_pid
          rescue Errno::ESRCH
            Logger.warn "master process #{@master_pid} not exist! when it was killed ."
          end
        end
      end
    end

  end

end
