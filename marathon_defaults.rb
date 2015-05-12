module MarathonDefaults

  @@preproduction_override = {
    :instances => 99,
    :mem => 99999,
    :cpus => 0.9999      
  } 
  
  @@preproduction_env = {
    :DATACENTER_NUMBER => 44,
    :JAVA_XMX => "256m"
  }  
  
  @@required_marathon_env_variables = %w[
    DATACENTER_NUMBER
    APPLICATION_NAME
  ]
  
  @@required_marathon_attributes = %w[id env container healthChecks args].map(&:to_sym)
  
  def self.symbolize(data) 
    data.inject({}){|h,(k,v)| h[k.to_sym] = v; h}
  end
  
  def self.missing_attributes(json)
    json = symbolize(json)
    missing = []
    @@required_marathon_attributes.each do |att|
      if (!json[att])
        missing << att 
      end
    end
    return missing
  end
  
  def self.missing_envs(json)
    json = symbolize(json)
    
    if (!json.key?(:env))
      abort("no env attribute found in deployment file") 
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
    json = symbolize(json)
      @@preproduction_override.each do |property,value|
        json[property] = value
      end
      return json
  end
  
  MarathonDefaults.private_class_method :symbolize
end