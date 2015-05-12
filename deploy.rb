require 'yaml_json'
require 'marathon_defaults'
require 'marathon_api'
require 'optparse'

# TODO
# log to database
# post to marathon
# datacenter handling, iterate
# inject envs DATACENTER_NUMBER, ENVIRONMENT 
  
options = {}
  
# DEFAULTS
production_environment_name = 'production'
default_environment_name = 'integration'
options[:deployfile] = 'deploy.yaml'
options[:verbose] = false
options[:environment] = default_environment_name
options[:marathon_url] = 'http://192.168.59.103:8080'
options[:marathon_app_path] = '/v2/apps'
  
OptionParser.new do |opts|
  opts.banner = "Usage: deploy.rb [options]"

  opts.on("-u", "--url MARATHON_URL", "Default: #{options[:marathon_url]}") do |u|
    options[:marathon_url] = u  
  end
  
  opts.on("-p", "--path MARATHON_API_PATH", "Default: #{options[:marathon_app_path]}") do |p|
    options[:marathon_app_path] = p  
  end
  
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  
  opts.on("-f", "--file DEPLOYFILE" ,"Deploy file with json or yaml file extension. Default: #{options[:deployfile]}") do |f|
    options[:deployfile] = f
  end
  
  opts.on("-e", "--environment ENVIRONMENT", "Default: #{default_environment_name}" ) do |e|
    options[:environment] = e
  end
  
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end 
end.parse!

deployfile = options[:deployfile]
environment = options[:environment]
marathon_app_post_url =  options[:marathon_url] + options[:marathon_app_path]

if (!File.exist?(File.join(File.expand_path(__dir__),deployfile)))
  abort("#{deployfile} not found in current directory #{File.join(File.expand_path(__dir__))}")
end

extension = File.extname(deployfile)
marathon_json = nil

case extension
when '.json'
  marathon_json = YamlJson.read_json(deployfile)
when '.yaml'
  marathon_json = YamlJson.yaml2json(deployfile)
else
  abort("File extension #{extension} is not supported for deployment file #{deployfile}")  
end  

missing_attributes = MarathonDefaults.missing_attributes(marathon_json)
if(!missing_attributes.empty?)
  abort("#{deployfile} is missing required marathon API attributes: #{missing_attributes.join(',')}")
end

missing_envs = MarathonDefaults.missing_envs(marathon_json)
if(!missing_envs.empty?)
  abort("#{deployfile} is missing required environment variables: #{missing_envs.join(',')}")
end

if(environment != production_environment_name)
  marathon_json = MarathonDefaults.overlay_preproduction_settings(marathon_json)
end


MarathonApi.post(marathon_app_post_url,marathon_json)

#puts JSON.pretty_generate(marathon_json)