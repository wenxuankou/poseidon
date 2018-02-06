require 'test_helper'

describe "Poseidon Configrator" do 
  it "have default config keys" do 
    %w(app host port time_out workers config_ru_path).each do |k|
      Poseidon::Configurator::ALL_OPTIONS.keys.must_include k.to_sym
    end
  end

  describe "Configurator attr methods" do 
    it "can get right setting" do 
      Poseidon::Configurator.port(8000).port.must_equal 8000
      Poseidon::Configurator.host('0.0.0.0').host.must_equal '0.0.0.0'
      Poseidon::Configurator.workers(2).workers.must_equal 2
      Poseidon::Configurator.time_out(100).time_out.must_equal 100
      Poseidon::Configurator.config_ru_path('test/config.ru').config_ru_path.must_equal 'test/config.ru'
    end
  end
end
