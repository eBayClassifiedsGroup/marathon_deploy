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
    if (response.is_a?(Net::HTTPResponse) && !response.body.nil?)
      return deep_symbolize((JSON.parse(response.body)))
    end
    return nil
  end
  
end