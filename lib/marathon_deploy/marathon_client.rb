require 'marathon_deploy/http_util'
require 'marathon_deploy/deployment'

# http://www.mudskipper-solutions.com/home/how-to-send-jsonhttp-using-ruby
# http://www.bls.gov/developers/api_ruby.htm
# https://gist.github.com/amirrajan/2369851
# http://mikeebert.tumblr.com/post/56891815151/posting-json-with-net-http

# https://github.com/augustl/net-http-cheat-sheet

class MarathonClient
  include HttpUtil

  attr_reader :marathon_url, :options
  attr_accessor :application
  @@marathon_apps_rest_path = '/v2/apps/'
    
  # TODO:  Options will contain environment, datacenter
  def initialize(url, options = {})
    @marathon_url = url
    @options = options
    if @options[:username] and @options[:password]
      @options[:basic_auth] = {
        :username => @options[:username],
        :password => @options[:password]
      }
      @options.delete(:username)
      @options.delete(:password)
    end
  end
  
  def list_app
    HttpUtil.get(@marathon_url + @@marathon_apps_rest_path + application.id)
  end
     
  def exists?
    response = list_app
    if (response.code.to_i == 200)
      return true
    end
      return false
  end

  def versions    
    return { :body => "Application #{application.id} is not deployed.", :code => '404' }.to_json if !self.exists?   
    url = @marathon_url + @@marathon_apps_rest_path + id + '/versions'
    $LOG.debug("Calling marathon api with url: #{url}")  
    response = HttpUtil.get(url)  
    return JSON.pretty_generate(JSON.parse(response.body))
  end
    
  def deploy
    deployment = Deployment.new(@marathon_url)

    deployment.wait(application.id)
    if (self.exists?)
      response = update_app
    else
      response = create_app
    end
    
    #puts deployment.deployments_for(application.id)
    deployment.wait(application.id)      
    # get status / health

  end

  private
    
  def create_app
    HttpUtil.post(@marathon_url + @@marathon_apps_rest_path,application.json)
  end
  
  def update_app(force=false)
    url = @marathon_url + @@marathon_apps_rest_path + application.id
    url += force ? '?force=true' : ''
    $LOG.debug("Updating app #{application.id}  #{url}")
    return HttpUtil.put(url,application.json)
  end
  
  def rolling_restart(app_id)
    url = @marathon_url + @@marathon_apps_rest_path + app_id + '/restart'
    $LOG.debug("Calling marathon api with url: #{url}") 
    response = HttpUtil.post(url,{})
    $LOG.info("Restart of #{application.id} returned status code: #{response.code}")
    $LOG.info(JSON.pretty_generate(JSON.parse(response.body)))
  end
  
end