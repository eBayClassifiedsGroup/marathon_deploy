

def get_macros(data)
  macros = Array.new
  IO.foreach(data) do |line|
    (macros  << line.scan(/(%\w+%)/)).flatten!
  end
  return macros
end

def get_env_keys
  return ENV.keys
end

def env_defined?(key)
  if (ENV.has_key?(key) && (!ENV[key].nil? && !ENV[key].empty? ))
    return true
  else
    return false
  end
end

def get_undefined_macros(macros)
  raise ArgumentError, "argument must be an array", caller if (!macros.class == Array)
  undefined = Array.new
  return macros.select { |m| !has_env?(m) }
end

def has_env?(macro)
  raise ArgumentError, "argument must be a String", caller if (!macro.class == String)
  env_name = strip(macro)
  if (env_defined?(strip(env_name)))
    return true
  else
    return false
  end
end

def strip(str)
  return str.gsub('%','')
end

def expand_macros(data)
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

class UndefinedMacroError < StandardError ; end

data = File.open('input.txt',"r")
puts expand_macros(data)