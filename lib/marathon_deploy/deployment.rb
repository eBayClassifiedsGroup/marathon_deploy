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

  def list
    HttpUtil.get(url + @@marathon_deployments_rest_path)
  end
  
  def deployments_for(id)
    response = list
    payload = JSON.parse(response.body)
    payload.collect { |d| d['affectedApps'] }.flatten.select { |a| a == '/' + id }
    results = Array.new  
    payload.each do |item|
      if (item['affectedApps'].select { |a| a == '/' + id })
        results << item
      end
    end
    return results
  end
  
  def running_for?(id)
    if (self.running? && !deployments_for(id).empty?)
      return true
    end
      return false
  end
  
  def running?
    response = list
    body = JSON.parse(response.body)
    return false if body.empty?
    return true
  end
  
  def wait(id)  
      Timeout::timeout(TIMEOUT) do
        while self.running_for?(id)
          response = list
          STDOUT.print "." if ( $LOG.level == 1 )
          $LOG.debug("Deployment of #{id} in progress")
          $LOG.debug(JSON.pretty_generate(JSON.parse(response.body)))       
          sleep(RECHECK_INTERVAL)
        end
        STDOUT.puts "" if ( $LOG.level == 1 )
      end    
  end
  
  # rollback
  def cancel
  end

end