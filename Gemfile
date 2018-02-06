source "https://gems.ruby-china.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in poseidon.gemspec
gemspec

gem 'rack', '~> 2.0.0'
# This gem is built on top of joyent/http-parser and its java port http-parser/http-parser.java.
gem 'http_parser.rb', github: 'tmm1/http_parser.rb.git', :tag => 'v0.6.0'
gem 'launchy'

group :test do 
  gem 'byebug'
  gem 'sinatra'
  gem 'minitest'
  gem 'excon'
end
