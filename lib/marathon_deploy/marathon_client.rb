require 'marathon_deploy/http_util'
require 'marathon_deploy/deployment'
require 'marathon_deploy/utils'
require 'marathon_deploy/marathon_defaults'

module MarathonDeploy
  class MarathonClient

  attr_reader :marathon_url, :options
  attr_accessor :application
    
  # TODO:  Options will contain environment, datacenter
  def initialize(url, options = {})
    
    raise Error::BadURLError, "invalid url => #{url}", caller if (!HttpUtil.valid_url(url))
   
    @marathon_url = HttpUtil.clean_url(url)
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

  def deploy
    
    deployment = Deployment.new(@marathon_url,application)
    
    $LOG.info("Checking if any deployments are already running for application #{application.id}")    
    begin
      deployment.wait_for_application("Deployment already running for application #{application.id}")
    rescue Timeout::Error => e
      raise Timeout::Error, "Timed out after #{deployment.timeout}s waiting for existing deployment of #{application.id} to finish. Check marathon ui #{@marathon_url + '/#deployments'} for stuck deployments!", caller
    end
    
    $LOG.info("Starting deployment of #{application.id}")

    # if application with this ID already exists
    if (deployment.applicationExists?)  
      $LOG.info("#{application.id} already exists. Performing update.")
      response = deployment.update_app      
         
    # if no application with this ID is seen in marathon
    else     
      response = deployment.create_app
    end

    if ((300..999).include?(response.code.to_i))
      $LOG.error("Deployment response body => " + JSON.pretty_generate(JSON.parse(response.body)))
      raise Error::DeploymentError, "Deployment returned response code #{response.code}", caller
    end
    
    $LOG.info("Deployment started for #{application.id} with deployment id #{deployment.deploymentId}") unless (deployment.deploymentId.nil?)
    
    # wait for deployment to finish, according to marathon deployment API call
    begin
      deployment.wait_for_deployment_id 
    rescue Timeout::Error => e
      $LOG.error("Timed out waiting for deployment of #{application.id} to complete. Canceling deploymentId #{deployment.deploymentId} and rolling back!")
      deployment.cancel(deployment.deploymentId)
      raise Timeout::Error, "Deployment of #{application.id} timed out after #{deployment.timeout} seconds", caller
    end 
     
    # wait for all instances with defined health checks to be healthy
    if (!deployment.health_checks_defined?)
      $LOG.warn("No health checks were defined for application #{application.id}. No health checking will be performed.")
    end
    
    begin
      deployment.wait_until_healthy
    rescue Timeout::Error => e
      raise Timeout::Error, "Timed out after #{deployment.healthcheck_timeout}s waiting for #{application.instances} instances of #{application.id} to become healthy. Check marathon ui #{@marathon_url + '/#deployments'} for more information.", caller
    end
  end
  
  end
end