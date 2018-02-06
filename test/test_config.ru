require 'sinatra'

get '/user' do 
  "hi nick!"
end

run Sinatra::Application
