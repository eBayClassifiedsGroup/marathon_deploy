require 'marathon_deploy/utils'
require 'marathon_deploy/error'
require 'logger'

module MarathonDeploy
  module MarathonDefaults
 
  DEPLOYMENT_RECHECK_INTERVAL = 3
  DEPLOYMENT_TIMEOUT = 300
  HEALTHY_WAIT_TIMEOUT = 300
  HEALTHY_WAIT_RECHECK_INTERVAL = 3
  PRODUCTION_ENVIRONMENT_NAME = 'PRODUCTION'
  DEFAULT_ENVIRONMENT_NAME = 'PREPRODUCTION'
  DEFAULT_PREPRODUCTION_MARATHON_ENDPOINTS = ['http://localhost:8080']
  DEFAULT_PRODUCTION_MARATHON_ENDPOINTS = ['http://paasmaster46-1.mobile.rz:8080']
  DEFAULT_DEPLOYFILE = 'deploy.yaml'
  DEFAULT_LOGFILE = false
  DEFAULT_LOGLEVEL = Logger::INFO
  MARATHON_APPS_REST_PATH = '/v2/apps/'
  MARATHON_DEPLOYMENT_REST_PATH = '/v2/deployments/'

  @@preproduction_override = {
    :instances => 5,
    :mem => 512,
    :cpus => 0.1      
  } 
  
  @@preproduction_env = {
    :DATACENTER_NUMBER => "44",
    :JAVA_XMS => "64m",
    :JAVA_XMX => "128m"
  }  
  
  @@required_marathon_env_variables = %w[]
  
  #@@required_marathon_attributes = %w[id env container healthChecks args storeUrls].map(&:to_sym)
  @@required_marathon_attributes = %w[id].map(&:to_sym)
   
  def self.missing_attributes(json)
    json = Utils.symbolize(json)
    missing = []
    @@required_marathon_attributes.each do |att|
      if (!json[att])
        missing << att 
      end
    end
    return missing
  end
  
  def self.missing_envs(json)
    json = Utils.symbolize(json)
    
    if (!json.key?(:env))
      raise Error::MissingMarathonAttributesError, "no env attribute found in deployment file", caller 
    end
    
    missing = []
    @@required_marathon_env_variables.each do |variable|
      if (!json[:env][variable])
        missing << variable 
      end
    end
    return missing
  end  
  
  def self.overlay_preproduction_settings(json)
    json = Utils.deep_symbolize(json)
      @@preproduction_override.each do |property,value|
        given_value = json[property]
        if (given_value > @@preproduction_override[property])
          $LOG.debug("Overriding property [#{property}: #{json[property]}] with preproduction default [#{property}: #{@@preproduction_override[property]}]")
          json[property] = @@preproduction_override[property]
        end
      end
      @@preproduction_env.each do |name,value|
        json[:env][name] = value
      end
      return json
  end
  
  end
end