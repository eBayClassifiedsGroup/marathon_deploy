require 'marathon_deploy/marathon_defaults'

module MarathonDeploy
  class Environment
  
  attr_reader :name
  
  def initialize(name)
    if (!name.is_a? String)
      raise Error::BadFormatError, "argument for environment must be a string", caller      
    end
    @name = name.upcase
  end
  
  def marathon_endpoints
    return 
  end
  
  def is_production?
    if (@name.casecmp(MarathonDefaults::PRODUCTION_ENVIRONMENT_NAME) == 0)
      return true
    end
    return false
  end
  
  def to_s
    @name
  end
  
  end
end