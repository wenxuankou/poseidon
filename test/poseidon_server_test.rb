require 'test_helper'
require 'excon'

describe "Poseidon Server" do 

  before do 
    start_server
  end

  after do 
    stop_server
  end

  describe "Poseidon can start normally" do 
    it "must connect the socket and get the right code and body" do 
      response = Excon.get("http://localhost:#{PORT}/user")
      response.status.must_equal 200
      response.body.must_match /hi nick!/
    end
  end

end
