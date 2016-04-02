require 'marathon_deploy/marathon_defaults'
require 'marathon_deploy/yaml_json'
require 'marathon_deploy/error'
require 'marathon_deploy/utils'
require 'deep_merge'

module MarathonDeploy
  
  class Application

  attr_reader :json, :id
  
  # Models an application to be added converted to json and send to the marathon-api
  # @param [Hash] options hash for the application object
  # @option options [Boolean] :force force a deployment by including an environment variable containing a random string value in the json marathon payload
  # @option options [String] :deployfile file template and path. default deploy.yml in current directory
  # @option options [MarathonDeploy::Environment] :environment environment specified with -e parameter
  def initialize(options={
      :force => false,
      :deployfile => 'deploy.yml',
      :remove_elements => [],
      :environment => nil,
  })

    deployfile = options[:deployfile]
    @json = readFile(deployfile)

    if (!options[:environment].nil?)
      overrides = env_overrides(
        File.dirname(deployfile),
        options[:environment].name)

      @json = @json.deep_merge!(overrides)
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
    remove_elements(options[:remove_elements])
      
    inject_envs = ENV.select { |k,v| /^#{MarathonDeploy::MarathonDefaults::ENVIRONMENT_VARIABLE_PREFIX}/.match(k)  }
    cleaned_envs = Hash[inject_envs.map { |k,v| [k.gsub(/^#{MarathonDeploy::MarathonDefaults::ENVIRONMENT_VARIABLE_PREFIX}/,''), v ] }]   
    self.add_envs cleaned_envs.to_h unless cleaned_envs.empty?
  end
  
  def overlay_preproduction_settings
    @json = MarathonDefaults.overlay_preproduction_settings(@json)
  end

  # @return [Array]
  def health_checks
    @json[:healthChecks]
  end
  
  def add_identifier
    random = Utils.random
    # Time.now.to_i
    @json[:env]['UNIQUE_ID'] = "#{id}_#{random}"
  end

  def remove_elements(remove_array)
    if (remove_array.is_a?(Array))
      remove_array.each do |element|
        @json.delete(element)
      end
    end
  end

  def to_s
    JSON.pretty_generate(@json)
  end
  
  # @return [JSON] list of ENV variables for this application 
  def env
    @json[:env]
  end
  
  def id
    @json[:id]
  end
  
  def add_envs(envs)
    if (!@json[:env])
      @json[:env] = {}
    end
    if (envs.is_a?(Hash))
      envs.each do |key,value|
        if (value.is_a? Numeric)
          @json[:env][key] = value.to_json
        else
          @json[:env][key] = value
        end
      end 
    else
      raise Error::BadFormatError, "argument must be a hash", caller
    end
  end
    
  def instances
    @json[:instances]  
  end

  private
  def readFile(f)
    $LOG.debug "Reading file #{f}"
    if (!File.exist?(f))
      message = "\'#{File.expand_path(f)}\' not found."
      raise Error::IOError, message, caller
    end

    extension = File.extname(f)

    case extension
      when '.json'
        json = YamlJson.read_json_w_macros(f)
      when '.yaml','.yml'
        json = YamlJson.yaml2json(f)
      else
        message = "File extension #{extension} is not supported for deployment file #{f}"
        raise Error::UnsupportedFileExtension, message, caller
    end

    # JSON fix for marathon
    # marathon require ENV variables to be quoted
    json['env'].each do |key, value|
      if (value.is_a? Numeric)
        json['env'][key] = value.to_json
      end
    end

    return json
  end

  def env_overrides(dir, env)
    yml = "#{dir}/#{env}.yml"
    if (File.exist?(yml))
      return readFile(yml)
    end

    json = "#{dir}/#{env}.json"
    if (File.exist?(json))
      return readFile(json)
    end

    return {}
  end
  end
end
