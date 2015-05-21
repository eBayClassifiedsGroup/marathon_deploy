require 'marathon_deploy/yaml_json'
yaml = ARGV[0]
puts YamlJson.json2yaml(yaml,false)
