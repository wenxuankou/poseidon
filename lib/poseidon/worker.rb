module Poseidon

  class Worker

    # app由master传入，因为app的加载是在master中进行的，由分叉产生
    # 的worker进程，无需再次加载
    def initialize(sockets = nil, app = nil, worker_pipe = nil, connection = nil)
      @sockets, @app, @worker_pipe = sockets, app, worker_pipe

      @protocol_parser = HttpParser.new

      # 存储客户端待处理连接
      @clients = {}

      # 将已经得到的连接加入待处理
      if connection
        @clients[connection.fileno] = Connection.new(connection)
      end
    end
    
    def start
      trap_signals

      loop do 
        # 筛选可以进行读或者写操作的IO对象
        to_read = @clients.values.select(&:ready_to_read?).map(&:client)
        to_write = @clients.values.select(&:ready_to_write?).map(&:client)

        readables, writables, = IO.select((to_read + @sockets), to_write)

        # 迭代可读/可写集合
        iterate_readables(readables)
        iterate_writables(writables)
        # 业务逻辑处理
        iterate_handleables(@clients.values.select(&:ready_to_handle?))
      end
    end

    # 发送心跳
    def heartbeat!
      begin
       @worker_pipe.write_nonblock '.'
      rescue Errno::EAGAIN
      rescue IOError
       Logger.error "when heartbeat: #{$!}"
      end
    end

    def trap_signals
      [:QUIT, :INT].each do |signal|
        trap(signal) do
          Logger.debug "Received #{signal} signal. Worker quit."

          exit
        end
      end

      [:CHLD, :USR1, :USR2].each do |signal|
        trap(signal) {}
      end
    end

    def iterate_readables(io_list)
      return if io_list.nil? || io_list.empty?

      io_list.map do |io|
        if @sockets.include?(io)
          # is sock
          _conn, _addrinfo = io.accept
          @clients[_conn.fileno] = Connection.new(_conn)
          # 发送心跳
          heartbeat!
          nil
        else
          # is connection
          # readable! 函数如果返回的是文件描述符id，证明此资源需要关闭。
          # 一般是由于连接断开导致的IOError
          @clients[io.fileno].readable!
        end
      end.each do |fileno|
        # 在读操作时，如果发生异常，则应该关闭连接，并且把连接移出待处理集合
        @clients.delete fileno
      end
    end

    def iterate_writables(io_list)
      return if io_list.nil? || io_list.empty?

      io_list.map do |io|
        # writable! 函数如果返回的是文件描述符id，证明此资源需要关闭
        # 一般是由于写操作完成或者连接断开导致的IOError
        @clients[io.fileno].writable!
      end.each do |fileno|
        # 在写操作时，如果发生异常，则应该关闭连接，并且把连接移出待处理集合
        @clients.delete fileno
      end
    end

    def iterate_handleables(conn_list)
      return if conn_list.nil? || conn_list.empty?

      conn_list.each do |conn|
        env = @protocol_parser.reset.parse(conn.request_raw)
        conn.response = @app.call rack_env_init.merge(env)
      end
    end

		def rack_env_init
      env = { 
        'rack.input' => StringIO.new(''.encode!(Encoding::ASCII_8BIT)),
        'rack.multithread' => false,
        'rack.multiprocess' => true,
        'rack.run_once' => false,
        'rack.errors' => STDERR,
        'rack.version' => [1, 0]
      }
		end

  end

end
