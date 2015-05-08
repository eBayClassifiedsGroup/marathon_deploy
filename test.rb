require 'yaml_json'
require 'marathon_defaults'

json = YamlJson.yaml2json(ARGV[0])

#puts json
puts "######"

#puts json["id"]
  
  
json_converted = MarathonDefaults.overlay_preproduction_settings(json)

puts JSON.pretty_generate(json_converted)

#YamlJson.json2yaml(ARGV[0])