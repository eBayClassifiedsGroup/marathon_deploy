require 'marathon_deploy/error'

module MarathonDeploy
  module Macro
  
  MACRO_BOUNDARY = '%%'
  
  def self.get_macros(data)
    macros = Array.new
    data.each do |line|
      (macros  << line.scan(/(#{MACRO_BOUNDARY}\w+#{MACRO_BOUNDARY})/)).flatten!
    end
    return macros
  end
  
  def self.get_env_keys
    return ENV.keys
  end
  
  def self.env_defined?(key)
    if (ENV.has_key?(key) && (!ENV[key].nil? && !ENV[key].empty? ))
      return true
    else
      return false
    end
  end
  
  def self.get_undefined_macros(macros)
    raise ArgumentError, "Argument must be an array", caller if (!macros.class == Array)
    undefined = Array.new
    return macros.select { |m| !has_env?(m) }
  end
  
  def self.has_env?(macro)
    raise ArgumentError, "Argument must be a String", caller if (!macro.class == String)
    env_name = strip(macro)
    if (env_defined?(strip(env_name)))
      return true
    else
      return false
    end
  end
  
  def self.strip(str)
    return str.gsub(MACRO_BOUNDARY,'')
  end
  
  def self.expand_macros(data)
    processed = ""
    macros = get_macros(data).uniq
    $LOG.debug("Macros found in deploy file: #{macros.join(',')}") unless (macros.empty?)
    undefined = get_undefined_macros(macros)
    if (!undefined.empty?)
      raise Error::UndefinedMacroError, "Macros found in deploy file without defined environment variables: #{undefined.join(',')}", caller
    end
  
    data.each do |line|
      macros.each do |m|
        env_value =  ENV[strip(m)].to_json
        line.gsub!(m, env_value)
      end
      processed += line
    end
    return processed  
  end
  
  def self.process_macros(filename)
    file = File.open(filename,'r')
    data = file.readlines
    file.close()
    return expand_macros(data)
  end
  
  private_class_method :get_macros, :get_env_keys, :strip, :has_env?, :get_undefined_macros, :env_defined?, :expand_macros
  
  end
end