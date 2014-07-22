 $:.push File.expand_path("../lib", __FILE__)
 require 'factor/version'

 Gem::Specification.new do |s|
  s.name          = "factor"
  s.version       = Factor::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Maciej Skierkowski"]
  s.email         = ["maciej@factor.io"]
  s.homepage      = "https://factor.io"
  s.summary       = %q{CLI to manager workflows on Factor.io}
  s.description   = %q{CLI to manager workflows on Factor.io}

  s.files         = %x{git ls-files}.split("\n")
  s.test_files    = %x{git ls-files -- {test,spec,features}/*}.split("\n")
  s.executables   = %x{git ls-files -- bin/*}.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'commander', '~> 4.1.5'
  s.add_runtime_dependency 'rest_client', '~> 1.7.3'
  s.add_runtime_dependency 'faye-websocket', '~> 0.7.2'
  s.add_runtime_dependency 'colored', '~> 1.2'
  s.add_runtime_dependency 'configatron', '~> 4.2.0'
 end