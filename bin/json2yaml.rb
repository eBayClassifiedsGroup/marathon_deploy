#!/usr/bin/env ruby

require 'marathon_deploy/yaml_json'
yaml = ARGV[0]
puts MarathonDeploy::YamlJson.json2yaml(yaml,false)
