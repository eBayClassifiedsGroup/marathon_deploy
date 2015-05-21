require 'yaml'
require 'json'
require 'marathon_deploy/macro'

module YamlJson
  
  def self.yaml2json(filename, process_macros=true)  
    if (process_macros)
      begin
        data = YAML::load(Macro::process_macros(filename))
      rescue Error::UndefinedMacroError => e
        abort(e.message)     
      end
    else
      data = YAML::load_file(filename)
    end
    JSON.parse(JSON.dump(data))
  end
  
  def self.json2yaml(filename, process_macros=true)
    if (process_macros)
      json = read_json_w_macros(filename)
    else
      json = read_json(filename)
    end
    yml = YAML::dump(json)
  end
  
  def self.read_json(filename)
    file = File.open(filename,'r')
    data = file.read 
    file.close
    return JSON.parse(data)
  end  
  
  def self.read_json_w_macros(filename)
    begin
      data = Macro::process_macros(filename)
    rescue Error::UndefinedMacroError => e
      abort(e.message)
    end
    return JSON.parse(data)
  end  
  
end