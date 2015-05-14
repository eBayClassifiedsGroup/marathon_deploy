require 'marathon_deploy/marathon_defaults'
require 'marathon_deploy/marathon_client'
require 'marathon_deploy/error'
require 'marathon_deploy/application'
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
production_environment_name = 'PRODUCTION'
default_environment_name = 'INTEGRATION'
options[:deployfile] = 'deploy.yaml'
options[:verbose] = Logger::INFO
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
    options[:environment] = e.upcase
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
marathon_url = options[:marathon_url]

begin
  application = Application.new(deployfile)
rescue Error::UnsupportedFileExtension => e
  $LOG.error(e)
  exit!
rescue Error::IOError => e
  $LOG.error(e)
  exit!
rescue Error::MissingMarathonAttributesError => e
  $LOG.error(e)
  exit!
end

#puts application.json

begin
  application.add_envs({ :APPLICATION_NAME => application.id, :ENVIRONMENT => environment})
rescue Error::BadFormatError => e
  $LOG.error(e)
  exit!
end

puts "#" * 100
puts JSON.pretty_generate(application.json)
puts "#" * 100

client = MarathonClient.new(marathon_url)

client.application = application
client.deploy