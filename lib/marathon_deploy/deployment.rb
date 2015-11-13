require 'marathon_deploy/http_util'
require 'marathon_deploy/utils'
require 'marathon_deploy/marathon_defaults'
require 'timeout'

module MarathonDeploy
  class Deployment
  
  DEPLOYMENT_RECHECK_INTERVAL = MarathonDefaults::DEPLOYMENT_RECHECK_INTERVAL
  DEPLOYMENT_TIMEOUT = MarathonDefaults::DEPLOYMENT_TIMEOUT
  HEALTHY_WAIT_TIMEOUT = MarathonDefaults::HEALTHY_WAIT_TIMEOUT
  HEALTHY_WAIT_RECHECK_INTERVAL = MarathonDefaults::HEALTHY_WAIT_RECHECK_INTERVAL
  
  attr_reader :url, :application, :deploymentId
  
  def initialize(url, application)
    raise ArgumentError, "second argument to deployment object must be an Application", caller unless (!application.nil? && application.class == Application)
    raise Error::BadURLError, "invalid url => #{url}", caller if (!HttpUtil.valid_url(url))    
    @url = HttpUtil.clean_url(url)
    @application = application
  end
  
  def timeout
    return DEPLOYMENT_TIMEOUT
  end
  
  def healthcheck_timeout
    return HEALTHY_WAIT_TIMEOUT
  end
  
  def versions  
    if (!applicationExists?)  
      response = HttpUtil.get(@url + MarathonDefaults::MARATHON_APPS_REST_PATH + @application.id + '/versions')  
      response_body = Utils.response_body(response)
      return response_body[:versions]
    else
      return Array.new
    end
  end
     
  def wait_for_deployment_id(message = "Deployment with deploymentId #{@deploymentId} in progress")
      startTime = Time.now
      deployment_seen = false  
      Timeout::timeout(DEPLOYMENT_TIMEOUT) do
        while running_for_deployment_id?

          deployment_seen = true
          #response = list_all
          #STDOUT.print "." if ( $LOG.level == 1 )
          elapsedTime = '%.2f' % (Time.now - startTime)
          $LOG.info(message + " (elapsed time #{elapsedTime}s)")
          deployments = deployments_for_deployment_id
          deployments.each do |item|
            $LOG.debug(deployment_string(item))
          end   
          sleep(DEPLOYMENT_RECHECK_INTERVAL)
        end        
        #STDOUT.puts "" if ( $LOG.level == 1 )
        if (deployment_seen)
          elapsedTime = '%.2f' % (Time.now - startTime)
          $LOG.info("Deployment with deploymentId #{@deploymentId} ended (Total deployment time #{elapsedTime}s)")  
        end
      end
  end
  
  def wait_for_application(message = "Deployment of application #{@application.id} in progress")
      deployment_seen = false  
      Timeout::timeout(DEPLOYMENT_TIMEOUT) do
        while running_for_application_id?
          deployment_seen = true
          #response = list_all
          #STDOUT.print "." if ( $LOG.level == 1 )
          $LOG.info(message)
          deployments_for_application_id.each do |item|
            $LOG.debug(deployment_string(item))
          end
          #$LOG.debug(JSON.pretty_generate(JSON.parse(response.body)))       
          sleep(DEPLOYMENT_RECHECK_INTERVAL)
        end                
        #STDOUT.puts "" if ( $LOG.level == 1 )
        if (deployment_seen)
          $LOG.info("Deployment of application #{@application.id} ended")  
        end
      end    
  end
  
  def wait_until_healthy  
    startTime = Time.now  
    Timeout::timeout(HEALTHY_WAIT_TIMEOUT) do
      loop do
        break if (!health_checks_defined?)
        sick = get_alive(false)
        elapsedTime = '%.2f' % (Time.now - startTime)
        if (!sick.empty?)
          $LOG.info("#{sick.size}/#{@application.instances} instances are not healthy, retrying in #{HEALTHY_WAIT_RECHECK_INTERVAL}s (elapsed time #{elapsedTime}s)")
          $LOG.debug("Sick instances: " + sick.join(','))
        else         
          healthy = get_alive(true)
          if (healthy.size == @application.instances)
            elapsedTime = '%.2f' % (Time.now - startTime)
            $LOG.info("#{healthy.size} of #{@application.instances} expected instances are healthy (Total health-check time #{elapsedTime}s).")
            $LOG.debug("Healthy instances running: " + healthy.join(','))
            break
          else
            $LOG.info("#{healthy.size} healthy instances seen, #{@application.instances} healthy instances expected, retrying in #{HEALTHY_WAIT_RECHECK_INTERVAL}s")
          end
        end      
        sleep(HEALTHY_WAIT_RECHECK_INTERVAL)
      end                         
    end  
  end
    
  def cancel(deploymentId,force=false)
    raise ArgumentError, "deploymentId must be specified to cancel deployment", caller if (deploymentId.empty?)
    if (running_for_deployment_id?)
      response = HttpUtil.delete(@url + MarathonDefaults::MARATHON_DEPLOYMENT_REST_PATH + deploymentId + "?force=#{force}")
      $LOG.debug("Cancellation response [#{response.code}] => " + JSON.pretty_generate(JSON.parse(response.body)))
    end
    return response
  end
  
  def applicationExists?
    response = list_app
    if (response.code.to_i == 200)
      return true
    end
      return false
  end
       
  def create_app
    response = HttpUtil.post(@url + MarathonDefaults::MARATHON_APPS_REST_PATH,@application.json)
    @deploymentId = get_deployment_id
    return response
  end
  
  def update_app(force=false)
    url = @url + MarathonDefaults::MARATHON_APPS_REST_PATH + @application.id
    url += force ? '?force=true' : ''
    $LOG.debug("Updating app #{@application.id} #{url}")
    response = HttpUtil.put(url,@application.json)    
    @deploymentId = Utils.response_body(response)[:deploymentId]
    return response
  end
  
  def rolling_restart
    url = @url + MarathonDefaults::MARATHON_APPS_REST_PATH + @application.id + '/restart'
    $LOG.debug("Calling marathon api with url: #{url}") 
    response = HttpUtil.post(url,{})
    $LOG.info("Restart of #{@application.id} returned status code: #{response.code}")
    $LOG.info(JSON.pretty_generate(JSON.parse(response.body)))
  end  
  
  def health_checks_defined?
    health_checks = @application.health_checks
    return true unless health_checks.nil? or health_checks.empty?
    return false
  end  
  
  ####### PRIVATE METHODS ##########
  private

  # returns an array of taskIds which are alive
  def get_alive(value) 
    raise ArgumentError, "value must be boolean true or false" unless (!!value == value)       
    if (health_checks_defined?)     
        apps = Array.new
        begin
          apps = Utils.getValue(@url,@application,:app)
        rescue Exception=>e
          $LOG.info "EXCEPTION: #{e} Cannot determine apps"
        end

        if (apps.nil? or apps.empty?)
          raise Error::DeploymentError, "Marathon API returned an empty app or nil json object for application #{@application.id}", caller
        else
          tasks = Hash.new
          task_ids = Array.new
          check_results = get_healthcheck_results.flatten
          check_results.each do |task| 
            next if task.nil?  
            tasks[task[:taskId].to_s] ||= [] 
          tasks[task[:taskId].to_s] << task[:alive]
          end
          
          tasks.each do |k,v|            
            if (value)
              # if there are only alive=true for all healthchecks for this instance
              if (v.uniq.length == 1 && v.uniq.first == value)
                task_ids << k
              end 
            else
              # if alive=false is seen for any healthchecks for this instance
              if (v.include?(value))
                task_ids << k
              end 
            end            
          end         
        end
    else
      $LOG.info("No health checks defined. Cannot determine application health of #{@application.id}.")    
    end
    return task_ids
  end

  def get_task_ids
    begin
      a = Utils.getValue(@url,@application,:app,:tasks).collect { |task| task[:id]}
      return a
    rescue Exception=>e
      $LOG.info "EXCEPTION: #{e} Cannot determine task_ids"
    end
  end

  def get_healthcheck_results
    begin
      a = Utils.getValue(@url,@application,:app,:tasks).collect { |task| task[:healthCheckResults]}
      return a
    rescue Exception=>e
      $LOG.info "EXCEPTION: #{e} Cannot determine healthcheck_result"
    end
  end
    
  def get_deployment_id
    begin
      a = Utils.getValue(@url,@application,:app,:deployments,0)[:id]
      return a
    rescue Exception=>e
      $LOG.info "EXCEPTION: #{e} Cannot determine deployment_id"
    end
  end
    
  def list_all
    HttpUtil.get(@url + MarathonDefaults::MARATHON_DEPLOYMENT_REST_PATH)
  end 
  
  def running_for_application_id?
    if (deployment_running? && !deployments_for_application_id.empty?)
      return true
    end
      return false
  end
  
  def running_for_deployment_id?
    if (deployment_running? && !deployments_for_deployment_id.empty?)
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
   
  def get_deployment_ids
    response = list_all
    payload = JSON.parse(response.body)
    return payload.collect { |d| d['id'] }
  end
  
  def list_app
    HttpUtil.get(@url + MarathonDefaults::MARATHON_APPS_REST_PATH + @application.id)
  end
  
  # DONT USE: the response seems to be broken in marathon for /v2/apps/application-id/tasks
  #def get_tasks
  #  HttpUtil.get(@url + MarathonDefaults::MARATHON_APPS_REST_PATH + @application.id + '/tasks')
  #end
  
  def deployment_string(deploymentJsonObject)  
    string = "\n" + "+-" * 25 + " DEPLOYMENT INFO  " + "+-" * 25 + "\n"
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
   return string 
  end
    
  def deployments_for_deployment_id
    response = list_all
    payload = JSON.parse(response.body)
    return payload.find_all { |d| d['id'] == @deploymentId }
  end
  
  def deployments_for_application_id
    response = list_all
    payload = JSON.parse(response.body)
    return payload.find_all { |d| d['affectedApps'].include?('/' + @application.id) }
  end
  
  end
end
