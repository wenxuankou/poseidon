module Poseidon

  class Worker

    def initialize(sockets, app, writable_pipe, connection = nil)
      @sockets, @app, @writable_pipe = sockets, app, writable_pipe
      @http_parser = HttpParser.new

      @clients = {}

      if connection
        @clients[connection.fileno] = Connection.new(connection, @http_parser)
      end
    end
    
    def start
      trap_signals

      loop do 
        to_read = @clients.values.select(&:ready_to_read?).map(&:client)
        to_write = @clients.values.select(&:ready_to_write?).map(&:client)

        readables, writables = IO.select((to_read + @sockets), to_write)

        iterate_readables(readables)
        iterate_writables(writables)
      end
    end

    def heartbeat!
     begin
       @writable_pipe.write_nonblock '.'
     rescue Errno::EAGAIN
     rescue IOError
       Logger.error "when heartbeat: #{$!}"
     end
    end

    def trap_signals
      trap(:QUIT) do
        Logger.debug "Received :QUIT signal. Worker quit."

        exit
      end
    end

    def iterate_readables(io_list)
    end

    def iterate_writables(io_list)
    end

  end

end
