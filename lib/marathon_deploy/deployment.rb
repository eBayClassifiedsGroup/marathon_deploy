require 'marathon_deploy/http_util'
require 'timeout'

class Deployment
  include HttpUtil
  
  RECHECK_INTERVAL = 3
  TIMEOUT = 180
  
  @@marathon_deployments_rest_path = '/v2/deployments/'
  attr_reader :url
  
  def initialize(url)
    @url = url
  end
  
  def timeout
    return TIMEOUT
  end

  def list
    HttpUtil.get(url + @@marathon_deployments_rest_path)
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
    response = list
    body = JSON.parse(response.body)
    return false if body.empty?
    return true
  end
    
  def wait_for_deployment_id(deploymentId, message = "Deployment with deploymentId #{deploymentId} in progress")
      deployment_seen = false  
      Timeout::timeout(TIMEOUT) do
        while running_for_deployment_id?(deploymentId)

          deployment_seen = true
          #response = list
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
          #response = list
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
    
  # ie, rollback
  def cancel
  end
  
  private
  
  def get_deployment_ids
    response = list
    payload = JSON.parse(response.body)
    return payload.collect { |d| d['id'] }
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
    response = list
    payload = JSON.parse(response.body)
    return payload.find_all { |d| d['id'] == deploymentId }
  end
  
  def deployments_for_application_id(applicationId)
    response = list
    payload = JSON.parse(response.body)
    return payload.find_all { |d| d['affectedApps'].include?('/' + applicationId) }
  end
  

end