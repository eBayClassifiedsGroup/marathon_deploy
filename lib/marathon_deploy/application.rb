require 'marathon_deploy/marathon_defaults'
require 'marathon_deploy/yaml_json'
require 'marathon_deploy/error'
require 'marathon_deploy/utils'

module MarathonDeploy
  
  class Application

  attr_reader :json, :id
  
  # Models an application to be added converted to json and send to the marathon-api
  # @param [Hash] options hash for the application object
  # @option options [Boolean] :force force a deployment by including an environment variable containing a random string value in the json marathon payload
  # @option options [String] :deployfile file template and path. default deploy.yml in current directory
  def initialize(options={ :force => false, :deployfile => 'deploy.yml'})

    deployfile = options[:deployfile]
    
    if (!File.exist?(deployfile))
      message = "\'#{File.expand_path(deployfile)}\' not found."
      raise Error::IOError, message, caller
    end

    extension = File.extname(deployfile)
    
    case extension
      when '.json'
        @json = YamlJson.read_json(deployfile)
      when '.yaml','.yml'
        @json = YamlJson.yaml2json(deployfile)
      else
        message = "File extension #{extension} is not supported for deployment file #{deployfile}"
        raise Error::UnsupportedFileExtension, message, caller
    end 
    
    missing_attributes = MarathonDefaults.missing_attributes(@json) 
    
    if(!missing_attributes.empty?)
      message = "#{deployfile} is missing required marathon API attributes: #{missing_attributes.join(',')}"
      raise Error::MissingMarathonAttributesError, message, caller
    end
    
    missing_envs = MarathonDefaults.missing_envs(@json)
    if(!missing_envs.empty?)
      message = "#{deployfile} is missing required environment variables: #{missing_envs.join(',')}"
      raise Error::MissingMarathonAttributesError, message, caller
    end
     
    @deployfile = deployfile                
    @json =  Utils.deep_symbolize(@json)  
      
    add_identifier if (options[:force])
      
    inject_envs = ENV.select { |k,v| /^#{MarathonDeploy::MarathonDefaults::ENVIRONMENT_VARIABLE_PREFIX}/.match(k)  }
    cleaned_envs = inject_envs.map { |k,v| [k.gsub(/^#{MarathonDeploy::MarathonDefaults::ENVIRONMENT_VARIABLE_PREFIX}/,''), v ] }.to_h    
    self.add_envs cleaned_envs
  end
  
  def overlay_preproduction_settings
    @json = MarathonDefaults.overlay_preproduction_settings(@json)
  end
  
  def add_identifier
    random = Utils.random
    # Time.now.to_i
    json[:env]['UNIQUE_ID'] = "#{id}_#{random}"
  end
  
  def to_s
    return JSON.pretty_generate(@json)
  end
  
  def env
    @json[:env]
  end
  
  def id
    if (@json[:id])
      return @json[:id]
    end
  end
  
  def add_envs(envs)
    if (envs.is_a?(Hash))
      envs.each do |key,value|
        @json[:env][key] = value
      end 
    else
      raise Error::BadFormatError, "argument must be a hash", caller
    end
  end
    
  def instances
    if (@json[:instances])
      return @json[:instances]
    end    
  end  
     
  end
end