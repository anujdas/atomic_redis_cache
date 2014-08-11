# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atomic_redis_cache/version'

Gem::Specification.new do |spec|
  spec.name          = "atomic_redis_cache"
  spec.version       = AtomicRedisCache::VERSION
  spec.authors       = ["Anuj Das"]
  spec.email         = ["anujdas@gmail.com"]
  spec.summary       = %q{Use Redis as a multi-process atomic cache to avoid thundering herds and long calculations}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/anujdas/atomic_redis_cache"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'redis'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'fakeredis'
  if RUBY_VERSION == '1.8.7'
    spec.add_development_dependency 'timecop', '0.5.2'
  else
    spec.add_development_dependency 'timecop'
  end
end
