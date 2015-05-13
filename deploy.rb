require 'yaml_json'
require 'marathon_deploy/marathon_defaults'
require 'marathon_deploy/marathon_api'
require 'optparse'
require 'logger'

# TODO
# SLACK notification
# https://mesosphere.com/blog/2015/04/02/continuous-deployment-with-mesos-marathon-docker/
# generate properties script
# log to database
# datacenter handling, iterate
# deployment status polling
# config assembler
# deploying app VERSIONS
# VERSION, default read ENV VARIABLE OR get via '-r' parameter
# DEFAULT VERSION ENVIRONMENT: TIMESTAMP - application - environment
# inject / replce minimumHealthCapacity is 1, maximumOverCapacity is 1

options = {}
  
# DEFAULTS
production_environment_name = 'production'
default_environment_name = 'integration'
options[:deployfile] = 'deploy.yaml'
options[:verbose] = Logger::WARN
options[:environment] = default_environment_name
options[:marathon_url] = 'http://192.168.59.103:8080'
options[:logfile] = false
  
OptionParser.new do |opts|
  opts.banner = "Usage: deploy.rb [options]"

  opts.on("-u", "--url MARATHON_URL", "Default: #{options[:marathon_url]}") do |u|
    options[:marathon_url] = u  
  end
    
  opts.on("-l", "--logfile LOGFILE", "Default: STDOUT") do |l|
    options[:logfile] = l  
  end
  
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = Logger::DEBUG
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

$LOG = options[:logfile] ? Logger.new(options[:logfile]) : Logger.new(STDOUT)
$LOG.level = options[:verbose]

deployfile = options[:deployfile]
environment = options[:environment]

#if (!File.exist?(File.join(File.expand_path(__dir__),deployfile)))
if (!File.exist?(File.join(Dir.pwd,deployfile)))
  $LOG.error("#{deployfile} not found in current directory #{File.join(Dir.pwd)}")
  exit!
end

extension = File.extname(deployfile)
marathon_json = nil

case extension
when '.json'
  marathon_json = YamlJson.read_json(deployfile)
when '.yaml'
  marathon_json = YamlJson.yaml2json(deployfile)
else
  $LOG.error("File extension #{extension} is not supported for deployment file #{deployfile}")
  exit!  
end  

missing_attributes = MarathonDefaults.missing_attributes(marathon_json)
if(!missing_attributes.empty?)
  $LOG.error("#{deployfile} is missing required marathon API attributes: #{missing_attributes.join(',')}")
  exit!
end

missing_envs = MarathonDefaults.missing_envs(marathon_json)
if(!missing_envs.empty?)
  $LOG.error("#{deployfile} is missing required environment variables: #{missing_envs.join(',')}")
  exit!
end

if(environment != production_environment_name)
  marathon_json = MarathonDefaults.overlay_preproduction_settings(marathon_json)
end

#puts marathon_json[:id]
#stuff = MarathonApi.get(options[:marathon_url] + options[:marathon_apps_api] + "/#{marathon_json[:id]}")

#  puts stuff.code
  
MarathonApi.versions(options[:marathon_url],marathon_json)
  
#response = MarathonApi.post(options[:marathon_url] + '/v2/apps',marathon_json)
  
puts JSON.pretty_generate(marathon_json)
  
puts "SEND TO MARATHON: " + options[:marathon_url] + '/v2/apps/' + marathon_json[:id]
response = MarathonApi.put(options[:marathon_url] + '/v2/apps/' + marathon_json[:id],marathon_json)

puts response.body
puts response.code

#puts JSON.pretty_generate(marathon_json)