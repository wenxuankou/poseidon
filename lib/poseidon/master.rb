module Poseidon

  class Master
    
    def initialize(connection, sockets)
      @conn = connection
      @sockets = sockets

      # master 与 worker 之间的管道，用于心跳通讯
      @master_pipe, @worker_pipe = IO.pipe
      # 信号捕获后通过管道将信号输出，由专门的信号
      # 处理逻辑处理
      @read_signal_pipe, @write_signal_pipe = IO.pipe

      @worker_pids = []
    end

    def start
      trap_signals

      # 加载我们的应用
      load_app!
      Logger.debug "Loaded the app."

      # 衍生出一个worker，让他处理一个已经接收到的连接
      spawn_worker(@conn)
      @conn.close

      # 根据配置，衍生出剩余worker
      (Config.workers - 1).times { spawn_worker }
      Logger.debug "Spawn workers done."

      # 新开一个线程等待心跳
      loop_heartbeat
      # 等待信号
      loop_signal
    end

    def loop_heartbeat
      Thread.new do 
        loop do 
          if time_out?(IO.select([@master_pipe], nil, nil, Config.time_out))
            Logger.debug "Time out after #{Config.time_out} s. Exiting."

            # 向管道发送退出信号
            @write_signal_pipe.puts "QUIT"
          else
            @readable_pipe.read_nonblock 1
          end
        end
      end
    end

    def loop_signal
      loop do 
        readable, = IO.select([@read_signal_pipe])
        handle_signal(readable.first.gets)
      end
    end

    # 衍生worker进程
    def spawn_worker(connection = nil)
      @worker_pids << fork do 

        $PROGRAM_NAME = "poseidon-worker"

        Worker.new(@sockets, @app, @worker_pipe, connection).start
      end
    end

    def load_app!
      @app, options = Rack::Builder.parse_file(File.expand_path(Config.config_ru_path, Config.root_path))
    end

    def trap_signals
      # 捕获信号后，输出到管道，等待Master读取并处理，
      # 这里没有在`trap`的代码块中直接处理，有一个很
      # 重要的原因，在`trap`代码块中，某些操作是不允
      # 许的，比如我们不能在代码块中出现加锁的操作，
      # 如果你使用了logger，将日志写入文件，就会失败
      # 因为文件写操作会加锁，所以，如果有多余的逻辑
      # 处理代码，我们最好把信号输出到管道
      [:QUIT, :INT, :CHLD, :USR1, :USR2].each do |signal|
        trap(signal) do 
          begin
            @write_signal_pipe.puts signal.to_s
          rescue IOError
             Logger.error "when signal puts: #{$!}"
          end
        end
      end
    end

    def time_out?(select_result)
      !select_result
    end

    def kill_workers(signal, be_kill_pids = nil)
      be_kill_pids = @worker_pids if be_kill_pids.nil?

      Array(be_kill_pids).each do |pid|
        begin
          Process.kill signal.to_sym, pid
        rescue Errno::ESRCH
        end
      end
    end

    def handle_signal(signal)
      case signal.chomp
      when "INT"
        _signal_int!
      when "QUIT"
        _signal_quit!
      when "CHLD"
        _signal_chld!
      else
      end
    end

    def _signal_chld!
      dead_pid_list = []

      @worker_pids.each do |pid|
        begin
          dead_pid_list << Process.waitpid(pid, Process::WNOHANG)
        rescue Errno::ECHILD
        end
      end
      Logger.debug "Received :CHLD signal. #{dead_pid_list.compact.count} workers dead. Restart it now."

      dead_pid_list.each { |pid| @worker_pids.delete pid }
      dead_pid_list.compact.count.times { spawn_worker }
    end

    def _signal_int!
      Logger.debug "Received :INT signal. Killing all workers."

      kill_workers :INT
      # 一定要显示调用Process.exit，而不是exit，因为涉及到多线程
      Process.exit
    end

    def _signal_quit!
      Logger.debug "Received :QUIT signal. Killing all workers."

      kill_workers :QUIT
      Process.exit
    end

  end

end
