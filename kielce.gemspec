require_relative "lib/kielce/version"

Gem::Specification.new do |s|
  s.name = "kielce"
  s.version = Kielce::VERSION
  s.executables << "kielce"

  s.summary = "An ERB-based templating engine for generating course documents."
  s.description = "Kielce is a templating engine that uses ERB to generate course documents from structured data files, with support for custom template methods and plugins."
  s.authors = ["Zachary Kurmas"]
  s.files = Dir.glob("lib/**/*") + Dir.glob("bin/*") + ["kielce.gemspec", "README.md"]
  s.bindir = "bin"
  s.require_paths = ["lib"]
  s.homepage = "https://github.com/kurmasz/KielceRB"
  s.license = "MIT"
  s.required_ruby_version = ">= 3.2"
  s.add_dependency "erb", "6.0.7"
end
