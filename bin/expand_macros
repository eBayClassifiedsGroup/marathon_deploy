#!/usr/bin/env ruby

require 'marathon_deploy/error'
require 'marathon_deploy/macro'
require 'marathon_deploy/version'
require 'optparse'
require 'logger'

DEFAULT_TEMPLATE_FILENAME = 'dockerfile.tpl'

options = {}
  
# DEFAULTS
options[:template] = DEFAULT_TEMPLATE_FILENAME
options[:debug] = Logger::FATAL #Logger::INFO
options[:outfile] = false
options[:logfile] = false
options[:force] = false
  
  
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.release =  MarathonDeploy::VERSION
  
  opts.on("-o","--outfile OUTFILE", String, "Default: STDOUT") do |o|   
    options[:outfile] = o 
  end
    
  opts.on("-l", "--logfile LOGFILE", "Default: STDOUT") do |l|
    options[:logfile] = l  
  end
  
  opts.on("-d", "--debug", "Run in debug mode") do |d|
    options[:debug] = Logger::DEBUG
  end
  
  opts.on("-v", "--version", "Version info") do |v|
    puts "#{$0} version #{opts.release}"
    exit!
  end
  
  opts.on("-f", "--force", "force overwrite of existing OUTFILE") do |f|
    options[:force] = true
  end
  
  opts.on("-t", "--template TEMPLATE_FILE" ,"Input file. Default: #{options[:template]}") do |t|
    options[:template] = t
  end
    
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end 
end.parse!

$LOG = options[:logfile] ? Logger.new(options[:logfile]) : Logger.new(STDOUT)
$LOG.level = options[:debug]

template = options[:template]

begin
  processed = MarathonDeploy::Macro.process_macros(template)
rescue MarathonDeploy::Error::UndefinedMacroError => e
  abort(e.message)
rescue Errno::ENOENT => e
  abort("Could not locate template file #{template}")
end

output = IO.new(STDOUT.fileno) 
outfile = options[:outfile]
if (outfile)
  abort("File #{outfile} already exists. Please remove or rename it.") if (File.exists?(outfile) && !options[:force])
  fd = IO.sysopen(outfile, "w")
  output = IO.new(fd,'w')
end
  
output.write processed
output.close
  