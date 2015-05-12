require 'net/http'
require 'uri'

# http://www.mudskipper-solutions.com/home/how-to-send-jsonhttp-using-ruby

class MarathonApi
  
  attr_accessor :application_json
  attr_reader :url, :options
  
  def initialize(url, options = {})
    @url = url    
  end
  
  def post(json)
    req = Net::HTTP::Post.new url.path
    req.body = json
    
    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => false) do |http|
      http.request req
    end
    
  end

  
end