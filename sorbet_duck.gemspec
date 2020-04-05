Gem::Specification.new do |spec|
  spec.name          = "sorbet_duck"
  spec.version       = '1.0.0'
  spec.authors       = ["Aaron Christiansen"]
  spec.email         = ["hello@aaronc.cc"]

  spec.summary       = %q{Duck typing for Sorbet}
  spec.homepage      = "https://github.com/AaronC81/sorbet_duck"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ffast"
  spec.add_dependency "parlour", "~> 2.1"
end
