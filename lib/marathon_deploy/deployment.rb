require 'marathon_deploy/http_util'
require 'marathon_deploy/utils'
require 'marathon_deploy/marathon_defaults'
require 'timeout'

class Deployment
  
  RECHECK_INTERVAL = MarathonDefaults::DEPLOYMENT_RECHECK_INTERVAL
  TIMEOUT = MarathonDefaults::DEPLOYMENT_TIMEOUT
  
  attr_reader :url
  
  def initialize(url)
    raise Error::BadURLError, "invalid url => #{url}", caller if (!HttpUtil.valid_url(url))    
    @url = HttpUtil.clean_url(url)
  end
  
  def timeout
    return TIMEOUT
  end
 
  def running_for_application_id?(applicationId)
    if (self.deployment_running? && !deployments_for_application_id(applicationId).empty?)
      return true
    end
      return false
  end
  
  def running_for_deployment_id?(deploymentId)
    if (self.deployment_running? && !deployments_for_deployment_id(deploymentId).empty?)
      return true
    end
      return false
  end
  
  def deployment_running?
    response = list_all
    body = JSON.parse(response.body)
    return false if body.empty?
    return true
  end
    
  def wait_for_deployment_id(deploymentId, message = "Deployment with deploymentId #{deploymentId} in progress")
      deployment_seen = false  
      Timeout::timeout(TIMEOUT) do
        while running_for_deployment_id?(deploymentId)

          deployment_seen = true
          #response = list_all
          #STDOUT.print "." if ( $LOG.level == 1 )
          $LOG.info(message)
          deployments = deployments_for_deployment_id(deploymentId)
          deployments_for_deployment_id(deploymentId).each do |item|
            $LOG.debug(deployment_string(item))
          end   
          sleep(RECHECK_INTERVAL)
        end        
        #STDOUT.puts "" if ( $LOG.level == 1 )
        if (deployment_seen)
          $LOG.info("Deployment with deploymentId #{deploymentId} ended")  
        end
      end    
  end
  
  def wait_for_application_id(applicationId, message = "Deployment of application #{applicationId} in progress")
      deployment_seen = false  
      Timeout::timeout(TIMEOUT) do
        while running_for_application_id?(applicationId)
          deployment_seen = true
          #response = list_all
          #STDOUT.print "." if ( $LOG.level == 1 )
          $LOG.info(message)
          deployments_for_application_id(applicationId).each do |item|
            $LOG.debug(deployment_string(item))
          end
          #$LOG.debug(JSON.pretty_generate(JSON.parse(response.body)))       
          sleep(RECHECK_INTERVAL)
        end                
        #STDOUT.puts "" if ( $LOG.level == 1 )
        if (deployment_seen)
          $LOG.info("Deployment of application #{applicationId} ended")  
        end
      end    
  end
    
  def cancel(deploymentId)
    raise Error::BadURLError, "deploymentId must be specified to cancel deployment", caller if (deploymentId.empty?)
    if (running_for_deployment_id?(deploymentId))
      HttpUtil.delete(@url + MarathonDefaults::MARATHON_DEPLOYMENT_REST_PATH + '/' + deploymentId)
    end
  end
  
  def applicationExists?(application)
    response = list_app(application)
    if (response.code.to_i == 200)
      return true
    end
      return false
  end
      
  def create_app(application)
    HttpUtil.post(@url + MarathonDefaults::MARATHON_APPS_REST_PATH,application.json)
  end
  
  def update_app(application,force=false)
    url = @url + MarathonDefaults::MARATHON_APPS_REST_PATH + application.id
    url += force ? '?force=true' : ''
    $LOG.debug("Updating app #{application.id}  #{url}")
    return HttpUtil.put(url,application.json)
  end
  
  def rolling_restart(application)
    url = @url + MarathonDefaults::MARATHON_APPS_REST_PATH + application.id + '/restart'
    $LOG.debug("Calling marathon api with url: #{url}") 
    response = HttpUtil.post(url,{})
    $LOG.info("Restart of #{application.id} returned status code: #{response.code}")
    $LOG.info(JSON.pretty_generate(JSON.parse(response.body)))
  end
  
  def get_deployment_id_for_application(application)
    response = list_app(application)
    payload = Utils.response_body(response)
    return payload[:app][:deployments].first[:id] unless (payload[:app].nil?)
    return nil
  end
  
  # TODO
  def is_healthy?(application)
    get_health_for_app(application)
    return true
  end
  
  private
  # TODO
  def get_health_for_app(application)
    puts "######### GET HEALTH FOR APP #########"
  end
  
  def list_all
    HttpUtil.get(@url + MarathonDefaults::MARATHON_DEPLOYMENT_REST_PATH)
  end  
  
  def get_deployment_ids
    response = list_all
    payload = JSON.parse(response.body)
    return payload.collect { |d| d['id'] }
  end
  
  def list_app(application)
    HttpUtil.get(@url + MarathonDefaults::MARATHON_APPS_REST_PATH + application.id)
  end
  
  def deployment_string(deploymentJsonObject)  
    string = "\n" + "-" * 100  + "\n"
    deploymentJsonObject.sort.each do |k,v|
      case v
      when String
        string += k + " => " + v + "\n"
      when Fixnum
        string += k + " => " + v.to_s + "\n"
      when Array
        string += k + " => " + v.join(',') + "\n"
      else
        string += "#{k} + #{v}\n"
      end
    end  
   return string + "-" * 100 
  end
    
  def deployments_for_deployment_id(deploymentId)
    response = list_all
    payload = JSON.parse(response.body)
    return payload.find_all { |d| d['id'] == deploymentId }
  end
  
  def deployments_for_application_id(applicationId)
    response = list_all
    payload = JSON.parse(response.body)
    return payload.find_all { |d| d['affectedApps'].include?('/' + applicationId) }
  end
  
end