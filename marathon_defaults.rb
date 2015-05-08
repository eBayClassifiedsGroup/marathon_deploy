module MarathonDefaults

  @@preproduction_override = {
    :instances => 99,
    :mem => 4096,
    :cpus => 0.9999      
  }    
  
  def self.symbolize(data) 
    data.inject({}){|h,(k,v)| h[k.to_sym] = v; h}
  end
  
  def self.override_preproduction_marathon_settings(json)
    json = symbolize(json)
      @@preproduction_override.each do |property,value|
        json[property] = value
      end
      return json
  end
  
  MarathonDefaults.private_class_method :symbolize
end