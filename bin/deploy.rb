#!/usr/bin/env ruby

require 'marathon_deploy/marathon_defaults'
require 'marathon_deploy/marathon_client'
require 'marathon_deploy/error'
require 'marathon_deploy/application'
require 'marathon_deploy/environment'
require 'optparse'
require 'logger'

options = {}
  
# DEFAULTS
options[:deployfile] = MarathonDeploy::MarathonDefaults::DEFAULT_DEPLOYFILE
options[:verbose] = MarathonDeploy::MarathonDefaults::DEFAULT_LOGLEVEL
options[:environment] = MarathonDeploy::MarathonDefaults::DEFAULT_ENVIRONMENT_NAME
options[:marathon_endpoints] = nil
options[:logfile] = MarathonDeploy::MarathonDefaults::DEFAULT_LOGFILE
  
OptionParser.new do |opts|
  opts.banner = "Usage: deploy.rb [options]"

  opts.on("-u","--url MARATHON_URL(S)", Array, "Default: #{options[:marathon_endpoints]}") do |u|    
    options[:marathon_endpoints] = u  
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
  
  opts.on("-e", "--environment ENVIRONMENT", "Default: #{options[:environment]}" ) do |e|
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
environment = MarathonDeploy::Environment.new(options[:environment])
  
marathon_endpoints = Array.new
if (options[:marathon_endpoints].nil?)
  if (environment.is_production?)
    marathon_endpoints = MarathonDeploy::MarathonDefaults::DEFAULT_PRODUCTION_MARATHON_ENDPOINTS
  else
    marathon_endpoints = MarathonDeploy::MarathonDefaults::DEFAULT_PREPRODUCTION_MARATHON_ENDPOINTS
  end
else
  marathon_endpoints = options[:marathon_endpoints]
end
 
begin
  application = MarathonDeploy::Application.new(deployfile)
rescue MarathonDeploy::Error::IOError, MarathonDeploy::Error::UndefinedMacroError,MarathonDeploy::Error::MissingMarathonAttributesError,MarathonDeploy::Error::UnsupportedFileExtension  => e
  $LOG.debug(e)
  $LOG.error(e.message)
  exit!
end

begin
  application.add_envs({ :APPLICATION_NAME => application.id, :ENVIRONMENT => environment})
rescue MarathonDeploy::Error::BadFormatError => e
  $LOG.error(e)
  exit!
end

if (!environment.is_production?)
  application.overlay_preproduction_settings
end

puts "#" * 100
puts JSON.pretty_generate(application.json)
puts "#" * 100

# deploy to each endpoint
marathon_endpoints.each do |marathon_url|
  begin
    client = MarathonDeploy::MarathonClient.new(marathon_url)
    client.application = application
    client.deploy  
  rescue MarathonDeploy::Error::MissingMarathonAttributesError,MarathonDeploy::Error::BadURLError, Timeout::Error => e
    $LOG.error(e.message)
    exit!
  rescue MarathonDeploy::Error::DeploymentError => e
    $LOG.error("Deployment of #{application} failed => #{e}")
    exit!
  rescue SocketError, MarathonDeploy::Error::MarathonError => e
    $LOG.error("Problem talking to marathon endpoint => #{marathon_url} (#{e.message})")
    exit!
  end

end
