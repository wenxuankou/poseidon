# ---
# Monitor主要负责激活Master，并且接收闲时请求，交给Master处理，
# 服务启动后，我们仅仅只是启动了一个Monitor，当Monitor收到连接
# 时，会激活Master，并将连接交付给它，随后Master会开始工作，衍
# 生出Workers，进而处理我们的连接，如果Workers超过指定时间没能
# 收到新的连接，Master会认为当前服务器空闲，随即杀死所有Worker
# 并且自我退出，随即继续由Monitor来接收空闲时期的连接，如果新的
# 连接到来，将重新激活Master，如此反复！以这种方式达到服务的可
# 伸缩，在没有多余请求需要处理的时候，关闭Worker进程
# ---

module Poseidon

  class Monitor

    include Singleton

    def start(sockets)
      # 捕获信号
      trap_signals

      Socket.accept_loop(sockets) do |connection|
        @master_pid = fork do

          $PROGRAM_NAME = "poseidon-master"

          # 激活Master, 并把请求交给Master处理
          Master.new(connection, sockets).start
        end

        # 关闭当前进程的连接副本
        connection.close

        # 阻塞等待Master进程结束
        Process.waitpid @master_pid
      end
    end

    # 每个进程都应该去捕获信号，衍生进程会继承父进
    # 程的信号处理逻辑，有时候这是我们不希望看到的，
    # 除非你确定衍生进程的信号处理和父进程相同
    def trap_signals
      [:QUIT, :INT].each do |signal|
        trap(signal) do 
          begin
            Process.kill(signal, @master_pid) if @master_pid
          rescue Errno::ESRCH
          end

          Process.exit
        end
      end
    end

  end

end
