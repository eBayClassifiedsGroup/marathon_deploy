require 'yaml_json'
yaml = ARGV[0]
puts YamlJson.json2yaml(yaml)
