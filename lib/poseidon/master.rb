module Poseidon

  class Master
    
    def initialize(connection, sockets)
      @conn = connection
      @sockets = sockets
      @readable_pipe, @writable_pipe = IO.pipe

      @worker_pids = []
    end

    def start
      trap_signals

      load_app!
      Logger.debug "Loaded the app."

      spawn_worker(@conn)
      @conn.close

      (Config.workers - 1).times { spawn_worker }
      Logger.debug "Spawn workers done."

      loop do 
        if time_out?(IO.select([@readable_pipe], nil, nil, Config.time_out))
          Logger.debug "Time out after #{Config.time_out} s. Exiting."
          kill_workers :QUIT
          exit
        else
          @readable_pipe.read_nonblock 1
        end
      end
    end

    private

    def spawn_worker(connection = nil)
      @worker_pids << fork do 

        $PROGRAM_NAME = "poseidon-worker"

        Worker.new(@sockets, @app, @writable_pipe, connection).start
      end
    end

    def load_app!
      @app, options = Rack::Builder.parse_file(Config.config_ru_path)
    end

    def trap_signals
      
      trap(:QUIT) do 
        Logger.debug "Received :QUIT signal. Killing all workers."

        kill_workers :QUIT
        exit
      end

      trap(:CHLD) do 
        Logger.debug "Received :CHLD signal. Restart it now."

        dead_pid_list = []

        @worker_pids.each do |pid|
          begin
            dead_pid_list << Process.waitpid(pid, Process::WNOHANG)
          rescue Errno::ECHILD
          end
        end

        rebirth_workers dead_pid_list.compact
      end

    end

    def rebirth_workers(dead_pid_list)
      Logger.debug "#{dead_pid_list.count} workers need rebirth."
      
      @worker_pids.delete dead_pid_list
      dead_pid_list.count.times { spawn_worker }
    end

    def time_out?(select_result)
      !select_result
    end

    def kill_workers(signal, be_kill_pids = nil)
      be_kill_pids = @worker_pids if be_kill_pids.nil?

      Array(be_kill_pids).each do |pid|
        begin
          Process.kill signal.to_sym, pid
        rescue Error::ESRCH
          Logger.warn "child process #{pid} not exist! when it was killed ."
        end
      end
    end

  end

end
