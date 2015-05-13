require 'net/http'
require 'uri'

# http://www.mudskipper-solutions.com/home/how-to-send-jsonhttp-using-ruby
# http://www.bls.gov/developers/api_ruby.htm
# https://gist.github.com/amirrajan/2369851
# http://mikeebert.tumblr.com/post/56891815151/posting-json-with-net-http

# https://github.com/augustl/net-http-cheat-sheet


# TODO create as class
module MarathonApi
  
  # instance
  #marathon_apps_path = '/v2/apps'
  
  def self.versions(url, payload)
    response = get(url + '/v2/apps/' + payload[:id] + '/versions')
      puts "### VERSIONS ###"
      print response
      puts "### ###"
  end
  
  def self.restart(url)
    # /v2/apps/{appId}/versions/{version}:
  end
  
  def self.deploy(url,payload)
    # check if id exists
     # NO: do post
     # YES: PUT /v2/apps/{appId}   
  end
  
  def self.put(url,payload)
    uri = construct_uri url 
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Put.new(uri.path)
      req.body = payload.to_json
      req["Content-Type"] = "application/json"
      response = http.request(req)
      print response
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
      req = Net::HTTP::Post.new(uri.path)
      req.body = payload.to_json
      req["Content-Type"] = "application/json"
      response = http.request(req)
    rescue Errno::ECONNREFUSED => e
      $LOG.error("Error calling marathon api: #{e.message}")
      exit!
    end
    return response
  end
  
  def self.construct_uri(url)
    return URI.parse(url)
  end
 
  def self.get(url)
    uri = construct_uri url
    begin
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    #req["Authorization"] ='SOMEAUTH'
    response = http.request(req)
    rescue  Errno::ECONNREFUSED => e
      $LOG.error("Error calling marathon api: #{e.message}")
      exit!
    end
    return  response
  end
 
  def self.print(response)
    begin
      puts JSON.pretty_generate(JSON.parse(response.body))
    rescue
      puts response
    end
  end
  
  #TODO:  add low-level get, post, put to privates
  MarathonApi.private_class_method :construct_uri, :print
  
end