require 'yaml_json'
require 'marathon_defaults'
require 'optparse'



# TODO
# log to database
# required marathon attributes 
# detect json / yaml file extension

  
options = {}
# defaults
options[:deployfile] = "deploy.yaml"
options[:verbose] = false

OptionParser.new do |opts|
  opts.banner = "Usage: deploy.rb [options]"

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  
  opts.on("-f", "--file DEPLOYFILE" ,"Deploy file. Default is 'deploy.yaml'") do |f|
    options[:deployfile] = f
  end
  
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!


if (!File.exist?(File.join(File.expand_path(__dir__),options[:deployfile])))
  abort("#{options[:deployfile]} not found in current directory #{File.join(File.expand_path(__dir__))}")
end

extension = File.extname(options[:deployfile])
  
case extension
when '.json'
  puts "its json"
when '.yaml'
  puts "its yaml"
else
  abort("File extension #{extension} is not supported")  
end  

marathon_json = YamlJson.yaml2json(options[:deployfile])

puts marathon_json
puts "######"

#puts json["id"]
  
  
json_converted = MarathonDefaults.overlay_preproduction_settings(marathon_json)

puts JSON.pretty_generate(json_converted)

#YamlJson.json2yaml(ARGV[0])