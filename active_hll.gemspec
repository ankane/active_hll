require_relative "lib/active_hll/version"

Gem::Specification.new do |spec|
  spec.name          = "active_hll"
  spec.version       = ActiveHll::VERSION
  spec.summary       = "HyperLogLog for Rails and Postgres"
  spec.homepage      = "https://github.com/ankane/active_hll"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "activerecord", ">= 6.1"
end
