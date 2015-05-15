require 'marathon_deploy/marathon_defaults'
require 'marathon_deploy/yaml_json'
require 'marathon_deploy/error'
require 'marathon_deploy/utils'

class Application
  
  attr_reader :json, :id
  attr_accessor :envs
  
  def initialize(deployfile)
    
    if (!File.exist?(File.join(Dir.pwd,deployfile)))
      message = "#{deployfile} not found in current directory #{File.join(Dir.pwd)}"
      raise Error::IOError, message, caller
    end

    extension = File.extname(deployfile)
    
    case extension
      when '.json'
        @json = YamlJson.read_json(deployfile)
      when '.yaml'
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
    

    @json =  Utils.deep_symbolize(@json)
    @deployfile = deployfile  
    
    self.add_identifier  
  end
  
  def overlay_preproduction_settings
    @json = MarathonDefaults.overlay_preproduction_settings(@json)
  end
  
  def add_identifier
    random = Utils.random
    # Time.now.to_i
    json[:env]['UNIQUE_ID'] = "#{id}_#{random}"
  end
  
  
  def id
    if (@json[:id])
      @json[:id]
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

end