module Poseidon

  module Configurator
    
    ALL_OPTIONS = {
      root_path: nil,
      port: 8088,
      host: nil,
      workers: 1,
      time_out: 300,
      config_ru_path: 'config.ru',
      stderr: $stderr,
      stdout: $stdout,
      logger: nil,
      protocol_parser: nil,
      ssl: false
    }

    class << self

      ALL_OPTIONS.each do |option, default_value|
        define_method(option) do |*arg|
          arg = arg.shift
          if arg
            instance_variable_set("@#{option}", arg)
          else
            instance_variable_get("@#{option}") || default_value
          end
        end
      end

    end

  end

  Config = Configurator

end
