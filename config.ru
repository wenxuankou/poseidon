require 'rack/lint'
require 'sinatra'

get '/user/:id' do 
  p params
  "hi nick!"
end

post '/user' do 
  p params
  "create user"
end

get '/redirect' do 
  redirect 'https://www.baidu.com'
end

use Rack::Lint
run Sinatra::Application
