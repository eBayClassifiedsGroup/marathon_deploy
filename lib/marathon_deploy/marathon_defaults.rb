module MarathonDefaults

  @@preproduction_override = {
    :instances => 1,
    :mem => 32,
    :cpus => 0.1      
  } 
  
  @@preproduction_env = {
    :DATACENTER_NUMBER => "44",
    :JAVA_XMS => "64m",
    :JAVA_XMX => "128m"
  }  
  
  @@required_marathon_env_variables = %w[
    DATACENTER_NUMBER
    APPLICATION_NAME
  ]
  
  #@@required_marathon_attributes = %w[id env container healthChecks args].map(&:to_sym)
  @@required_marathon_attributes = %w[id].map(&:to_sym)
  
  def self.symbolize(data) 
    data.inject({}){|h,(k,v)| h[k.to_sym] = v; h}
  end
  
  def self.deep_symbolize(obj)
    return obj.reduce({}) do |memo, (k, v)|
      memo.tap { |m| m[k.to_sym] = deep_symbolize(v) }
    end if obj.is_a? Hash
    
    return obj.reduce([]) do |memo, v| 
      memo << deep_symbolize(v); memo
    end if obj.is_a? Array
  
    obj
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
      $LOG.error("no env attribute found in deployment file") 
      exit!
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
    json = deep_symbolize(json)
      @@preproduction_override.each do |property,value|
        given_value = json[property]
        if (given_value > @@preproduction_override[property])
          $LOG.debug("overriding property [#{property}: #{json[property]}] with preproduction default [#{property}: #{@@preproduction_override[property]}]")
          json[property] = @@preproduction_override[property]
        end
      end
      @@preproduction_env.each do |name,value|
        json[:env][name] = value
      end
      return json
  end
  
  MarathonDefaults.private_class_method :symbolize
end