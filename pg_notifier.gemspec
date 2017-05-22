# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pg_notifier/version'

Gem::Specification.new do |spec|
  spec.name          = "pg_notifier"
  spec.version       = PgNotifier::VERSION
  spec.authors       = ["German Antsiferov"]
  spec.email         = ["dxdy@bk.ru"]

  spec.summary       = %q{Process notifies about postgresql notifications.}
  spec.description   = %q{Process notifies about postgresql notifications.}
  spec.homepage      = "https://github.com/mr-dxdy/pg_notifier.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "pg"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
