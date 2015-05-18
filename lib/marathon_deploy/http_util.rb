require 'net/http'
require 'uri'
require 'marathon_deploy/error'

module HttpUtil

  def self.put(url,payload)
    uri = construct_uri url 
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Put.new(uri.request_uri)
      req.body = payload.to_json
      req["Content-Type"] = "application/json"
      response = http.request(req)
    rescue Errno::ECONNREFUSED => e
      $LOG.error("Error calling marathon api: #{e.message}")
      exit!
    end
    return response
  end
  
  def self.post(url, payload)
    uri = construct_uri url 
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new(uri.request_uri)
      req.body = payload.to_json
      req["Content-Type"] = "application/json"
      response = http.request(req)
    rescue Errno::ECONNREFUSED => e
      message = "Error calling marathon api: #{e.message}"
      $LOG.error(message)
      raise Error::MarathonError, message, caller
    end
    return response
  end
  
  def self.construct_uri(url)
    raise Error::BadURLError unless (valid_url(url))
    return URI.parse(url)
  end
  
  def self.delete(url)
    uri = construct_uri url 
       begin
         http = Net::HTTP.new(uri.host, uri.port)
         req = Net::HTTP::Delete.new(uri.request_uri)         
         response = http.request(req)
       rescue Errno::ECONNREFUSED => e
         message = "Error calling marathon api: #{e.message}"
         $LOG.error(message)
         raise Error::MarathonError, message, caller
       end
       return response    
  end
  
  def self.clean_url(url)
    url.sub(/(\/)+$/,'')
  end
  
  def self.get(url)
    uri = construct_uri url
    begin
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(req)
    rescue  Errno::ECONNREFUSED => e
      message = "Error calling marathon api: #{e.message}"
      $LOG.error(message)
      raise Error::MarathonError, message, caller
    end
    return  response
  end
  
  def self.valid_url(url)
    if (url =~ /\A#{URI::regexp}\z/)
      return true
    end
    return false
  end
 
  def self.print(response)
    begin
      puts JSON.pretty_generate(JSON.parse(response.body))
    rescue
      puts response
    end
  end
  
end