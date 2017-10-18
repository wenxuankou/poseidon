module Poseidon
  
  class Server

    include Singleton

    def start
      sockets = Socket.tcp_server_sockets(Config.host, Config.port)

      Logger.info "Poseidon #{VERSION}"
      Logger.info "Listening on port #{sockets.first.local_address.ip_address}:#{Config.port}"
      Logger.info "Listening on port #{sockets.last.local_address.ip_address}:#{Config.port}"

      # 由监视器控制当前server是否处于活跃状态
      Monitor.instance.start(sockets)
      
      Logger.info "Poseidon start done."
    end

  end

end
