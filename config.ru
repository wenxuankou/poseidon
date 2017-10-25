app = lambda do |env|
  p env
  body = "Hello, World!"
  [200, {"Content-Type" => "text/plain"}, [body]]
end

run app
