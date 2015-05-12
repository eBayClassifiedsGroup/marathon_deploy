require 'net/http'
require 'uri'

# http://www.mudskipper-solutions.com/home/how-to-send-jsonhttp-using-ruby
# http://www.bls.gov/developers/api_ruby.htm
# https://gist.github.com/amirrajan/2369851
# http://mikeebert.tumblr.com/post/56891815151/posting-json-with-net-http

module MarathonApi
  
  def self.post(url, payload)
    uri = construct_uri url 
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    req.body = payload.to_json
    #req["Authorization"] ='SOMEAUTH'
    req["Content-Type"] = "application/json"
    print http.request(req)
  end
  
  def self.construct_uri(url)
    return URI.parse(url)
  end
 
  def self.get(url)
    uri = construct_uri url
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    #req["Authorization"] ='SOMEAUTH'
    print http.request(req)
  end
 
  def self.print(response)
    begin
      puts JSON.pretty_generate(JSON.parse(response.body))
    rescue
      puts response
    end
  end
  
  MarathonApi.private_class_method :construct_uri, :print
  
end