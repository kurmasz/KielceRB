Gem::Specification.new do |s|
  s.name        = 'kielce'
  s.version     = '2.0.5'
  s.executables  << 'kielce'

  s.date        = '2022-07-06'
  s.summary     = "An ERB-based templating engine for generating course documents."
  s.description = "An ERB-based templating engine for generating course documents. "
  s.authors     = ["Zachary Kurmas"]
  s.files       = Dir.glob('lib/**/*')
  s.homepage    = 'https://github.com/kurmasz/KielceRB'
  s.license       = 'MIT'
end