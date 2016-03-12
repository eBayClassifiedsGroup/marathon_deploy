require 'marathon_deploy/utils'
require 'marathon_deploy/error'
require 'logger'

module MarathonDeploy
  module MarathonDefaults
 
  class << self
    attr_accessor :marathon_username, :marathon_password
  end

  WAIT_FOR_DEPLOYMENT_TIMEOUT = 7
  DEPLOYMENT_RECHECK_INTERVAL = 3
  DEPLOYMENT_TIMEOUT = 300
  HEALTHY_WAIT_TIMEOUT = 300
  HEALTHY_WAIT_RECHECK_INTERVAL = 3
  PRODUCTION_ENVIRONMENT_NAME = 'PRODUCTION'
  DEFAULT_ENVIRONMENT_NAME = 'PREPRODUCTION'
  DEFAULT_PREPRODUCTION_MARATHON_ENDPOINTS = ['http://localhost:8080']
  DEFAULT_PRODUCTION_MARATHON_ENDPOINTS = ['http://localhost:8080']
  DEFAULT_DEPLOYFILE = 'deploy.yml'
  DEFAULT_LOGFILE = false
  DEFAULT_LOGLEVEL = Logger::INFO
  MARATHON_APPS_REST_PATH = '/v2/apps/'
  MARATHON_DEPLOYMENT_REST_PATH = '/v2/deployments/'
  DEFAULT_FORCE_DEPLOY = false
  DEFAULT_NOOP = false
  DEFAULT_REMOVE_ELEMENTS = []
  DEFAULT_KEEP_ELEMENTS = [':id']
  ENVIRONMENT_VARIABLE_PREFIX = 'MARATHON_DEPLOY_'
  marathon_username = nil
  marathon_password = nil

  @@preproduction_override = {
    :instances => 5,
    :mem => 4096,
    :cpus => 0.5
  }

  @@defaults_minimum= {
    :instances => 1,
    :mem => 256,
    :cpus => 0.1
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
        if (!json[property])
          $LOG.debug("Missing property [#{property}] overriding with default [#{property}: #{@@defaults_minimum[property]}]")
          json[property] = @@defaults_minimum[property]
        end
        given_value = json[property]
        if (given_value > @@preproduction_override[property])
          $LOG.debug("Overriding property [#{property}: #{json[property]}] with preproduction default [#{property}: #{@@preproduction_override[property]}]")
          json[property] = @@preproduction_override[property]
        end
      end
      return json
  end
  
  end
end
