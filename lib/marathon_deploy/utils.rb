require 'marathon_deploy/marathon_defaults'

module MarathonDeploy
  module Utils
  
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
  
  def self.random
    range = [*'0'..'9',*'A'..'Z',*'a'..'z']
    return Array.new(30){ range.sample }.join
  end
  
  def self.response_body(response)
    if (!response.body.nil? && !response.body.empty? && response.kind_of?(Net::HTTPSuccess))
      begin
        return deep_symbolize((JSON.parse(response.body)))
      rescue Exception=>e
        $LOG.info "EXCEPTION: #{e} Cannot parse JSON"
      end
    end
    return nil
  end

  def self.getValue(url,application,*keys)
    value = nil
    5.times { |i|
      i+=1
      model = response_body(HttpUtil.get(url + MarathonDefaults::MARATHON_APPS_REST_PATH + application.id))
      value = lookup(model, *keys) if (!model.nil? and !model.empty?)
      break if (!value.nil? and !value.empty?)
      $LOG.info "Application #{application.id} is not yet registered with Marathon. Waiting #{i} seconds then retrying ..."
      sleep i
    }
    value
  end

  def self.lookup(model, key, *rest)
    v = model[key]
    return v if rest.empty?
    v && lookup(v, *rest)
  end

  end 
end
