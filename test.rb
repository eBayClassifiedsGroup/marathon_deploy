require 'yaml_json'
require 'marathon_defaults'

json = YamlJson.yaml2json(ARGV[0])

#puts json
puts "######"

#puts json["id"]
  
  
json_converted = MarathonDefaults.override_preproduction_marathon_settings(json)

puts JSON.pretty_generate(json_converted)

#YamlJson.json2yaml(ARGV[0])