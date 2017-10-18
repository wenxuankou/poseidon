# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "poseidon/version"

Gem::Specification.new do |spec|
  spec.name          = "poseidon"
  spec.version       = Poseidon::VERSION
  spec.authors       = ["nick.kou"]
  spec.email         = ["wenxuankou1993@gmail.com"]

  spec.summary       = %q{A Simple Ruby HTTP Server}
  spec.description   = %q{A Simple Ruby HTTP Server, In the most concise way to express the Unix programming skills, Very suitable for learning, But it is not suitable for directly used in production}
  spec.homepage      = "https://github.com/wenxuankou/poseidon.git"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
