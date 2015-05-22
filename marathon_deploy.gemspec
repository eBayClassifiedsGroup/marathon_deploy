# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'marathon_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "marathon_deploy"
  spec.version       = MarathonDeploy::VERSION
  spec.authors       = ["Jonathan Colby"]
  spec.email         = ["jcolby@team.mobile.de"]
  spec.summary       = %q{Mesos/Marathon deployment tool.}
  spec.description   = %q{Pushes a yaml or json file to the Marathon API.}
  spec.homepage      = "https://github.com/joncolby/marathon_deploy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.files         << ["bin/deploy.rb"]
  spec.files         << ["bin/json2yaml.rb"]
  spec.files         << ["bin/expand_macros.rb"]
  
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency "logger"
  spec.add_dependency "json"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
