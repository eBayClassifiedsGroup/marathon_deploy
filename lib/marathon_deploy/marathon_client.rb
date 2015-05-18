require 'marathon_deploy/http_util'
require 'marathon_deploy/deployment'
require 'marathon_deploy/utils'
require 'marathon_deploy/marathon_defaults'

# http://www.mudskipper-solutions.com/home/how-to-send-jsonhttp-using-ruby
# http://www.bls.gov/developers/api_ruby.htm
# https://gist.github.com/amirrajan/2369851
# http://mikeebert.tumblr.com/post/56891815151/posting-json-with-net-http

# https://github.com/augustl/net-http-cheat-sheet

class MarathonClient

  attr_reader :marathon_url, :options
  attr_accessor :application
    
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
  
  def versions    
    return { :body => "Application #{application.id} is not deployed.", :code => '404' }.to_json if !self.exists?   
    url = @marathon_url + MarathonDefaults::MARATHON_APPS_REST_PATH + id + '/versions'
    $LOG.debug("Calling marathon api with url: #{url}")  
    response = HttpUtil.get(url)  
    return JSON.pretty_generate(JSON.parse(response.body))
  end
    
  def deploy
    deployment = Deployment.new(@marathon_url)
    
    $LOG.info("Checking for running deployments of application #{application.id}")
    begin
      deployment.wait_for_application_id(application.id, "Deployment already running for application #{application.id}")
    rescue Timeout::Error => e
      $LOG.error("Timed out waiting for existing deployment of #{application.id} to finish. Could not start new deployment.")
      $LOG.error("Check marathon #{@marathon_url + '/#deployments'} for stuck deployments!")
      exit!
    end 
    
    $LOG.info("Starting deployment of #{application.id}")

    if (deployment.applicationExists?(application))
      
      $LOG.info("#{application.id} already exists. Performing update.")
      response = deployment.update_app(application)
      
      if ((300..999).include?(response.code.to_i))
        raise Error::DeploymentError, "Deployment return response code #{response.code}", caller
      end
      
      response_body =  Utils.response_body(response) 
      deploymentId = response_body[:deploymentId]

    else     
      response = deployment.create_app(application)
      
      if ((300..999).include?(response.code.to_i))
        raise Error::DeploymentError, "Deployment return response code #{response.code}", caller
      end
      
      response_body = Utils.response_body(response)
      deploymentId = deployment.get_deployment_id_for_application(application)

    end
    
    $LOG.info("Deployment running for #{application.id} with deploymentId #{deploymentId}")
    
    begin
      deployment.wait_for_deployment_id(deploymentId) 
    rescue Timeout::Error => e
      $LOG.error("Timed out waiting for deployment of #{application.id} to complete.")
      $LOG.error("Cancelling deployment and rolling back!")
      # TODO: initiate rollback
      # TODO: check rollback
      raise Error::DeploymentError, "Deployment of #{application.id} timed out after #{deployment.timeout} seconds", caller
    end 
     
    # TODO
    # POLL FOR HEALTH
    # DO HEALTH CHECK AND POLL UNTIL HEALTHY
    # HEALTHY exit OK
    # SICK exit NOT OK

  end

  private
  

  
end