module MarathonDefaults

  @@preproduction_override = {
    :instances => 99,
    :mem => 99999,
    :cpus => 0.9999      
  } 
  
  @@preproduction_env = {
    :DATACENTER_NUMBER => 44,
    :JAVA_XMX => @@preproduction_override[:mem].to_s + "m",
  }   
  
  def self.symbolize(data) 
    data.inject({}){|h,(k,v)| h[k.to_sym] = v; h}
  end
  
  def self.overlay_preproduction_settings(json)
    json = symbolize(json)
      @@preproduction_override.each do |property,value|
        json[property] = value
      end
      
## TODO: handle environment variables
      
      return json
  end
  
  MarathonDefaults.private_class_method :symbolize
end