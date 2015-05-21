module Macro
  
  def self.get_macros(data)
    macros = Array.new
    IO.foreach(data) do |line|
      (macros  << line.scan(/(%\w+%)/)).flatten!
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
    raise ArgumentError, "argument must be an array", caller if (!macros.class == Array)
    undefined = Array.new
    return macros.select { |m| !has_env?(m) }
  end
  
  def self.has_env?(macro)
    raise ArgumentError, "argument must be a String", caller if (!macro.class == String)
    env_name = strip(macro)
    if (env_defined?(strip(env_name)))
      return true
    else
      return false
    end
  end
  
  def self.strip(str)
    return str.gsub('%','')
  end
  
  def self.expand_macros(data)
    processed = ""
    macros = get_macros(data)
    undefined = get_undefined_macros(macros)
    if (!undefined.empty?)
      raise UndefinedMacroError, "macros found without defined Environment variables: #{undefined.join(',')}", caller
    end
  
    IO.foreach(data) do |line|
      macros.each { |m| line.gsub!(m,ENV[strip(m)]) }
      processed += line
    end
    return processed  
  end
  
  private_class_method :get_macros, :get_env_keys, :strip, :has_env?, :get_undefined_macros, :env_defined?
  
end