require 'net/http'
require 'uri'
require 'marathon_deploy/error'

module MarathonDeploy
  module HttpUtil

@@o_timeout = 60.0
@@r_timeout = 60.0
@@og_timeout = 60.0
@@rg_timeout = 60.0

  def self.req(method, url, payload=nil, errors_are_fatal=false)
    uri = construct_uri url 
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = @@o_timeout
      http.read_timeout = @@r_timeout
      req = Net::HTTP.const_get(method).new(uri.request_uri)
      if MarathonDeploy::MarathonDefaults::marathon_username and MarathonDeploy::MarathonDefaults::marathon_password
        req.basic_auth(MarathonDeploy::MarathonDefaults::marathon_username, MarathonDeploy::MarathonDefaults::marathon_password)
      end
      if payload
        req.body = payload.to_json
      end
      req["Content-Type"] = "application/json"
      response = http.request(req)
    rescue Exception => e
      if errors_are_fatal
        $LOG.error("Error calling marathon api: #{e.message}")
        exit!
      else
        message = "Error calling marathon api: #{e.message}"
        $LOG.error(message)
        raise Error::MarathonError, message, caller
      end
    end
    return response
  end

  def self.put(url,payload)
    return self.req('Put', url, payload, true)
  end
  
  def self.post(url, payload)
    return self.req('Post', url, payload, false)
  end
  
  def self.construct_uri(url)
    raise Error::BadURLError unless (valid_url(url))
    return URI.parse(url)
  end
  
  def self.delete(url)
    return self.req('Delete', url, nil, false)
  end
  
  def self.clean_url(url)
    url.sub(/(\/)+$/,'')
  end
  
  def self.get(url)
    return self.req('Get', url, nil, false)
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
end
