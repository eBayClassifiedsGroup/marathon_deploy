require 'marathon_deploy/http_util'
require 'marathon_deploy/deployment'
require 'marathon_deploy/utils'

# http://www.mudskipper-solutions.com/home/how-to-send-jsonhttp-using-ruby
# http://www.bls.gov/developers/api_ruby.htm
# https://gist.github.com/amirrajan/2369851
# http://mikeebert.tumblr.com/post/56891815151/posting-json-with-net-http

# https://github.com/augustl/net-http-cheat-sheet

class MarathonClient

  attr_reader :marathon_url, :options
  attr_accessor :application
  @@marathon_apps_rest_path = '/v2/apps/'
    
  # TODO:  Options will contain environment, datacenter
  def initialize(url, options = {})
    
    raise Error::BadURLError, "invalid url => #{url}", caller if (!HttpUtil.valid_url(url))
   
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
    
    $LOG.info("Checking for already running deployments of #{application.id}")
    begin
      deployment.wait(application.id)
    rescue Timeout::Error => e
      $LOG.error("Timed out waiting for existing deployment of #{application.id} to finish. Could not start new deployment.")
      $LOG.error("Check marathon #{@marathon_url + '/#deployments'} for stuck deployments!")
      exit!
    end 
    
    $LOG.info("Starting deployment of #{application.id}")
    if (self.exists?)
      $LOG.info("#{application.id} already exists. Performing update.")
      response = update_app
      status =  Utils.parse_response(response)
      puts "===>"
      puts status[:deploymentId]
      puts "<==="
    else     
      response = create_app
      puts response.body
    end
    
    #puts deployment.deployments_for(application.id)
    begin
      deployment.wait(application.id)
    rescue Timeout::Error => e
      $LOG.error("Timed out waiting for deployment of #{application.id} to complete.")
      $LOG.error("Cancelling deployment and rolling back!")
      # initiate rollback
      # check rollback
      # do not exit
    end      
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