module YamlJson
  
require 'yaml'
require 'json'

  def self.yaml2json(filename)
    data = YAML::load_file(filename)
    JSON.parse(JSON.dump(data))
  end
  
  def self.json2yaml(filename)
    json = read_json(filename)
    yml = YAML::dump(json)
  end
  
  def self.read_json(filename)
    file = File.open(filename,'r')
    data = file.read   
    file.close
    return JSON.parse(data)
  end
  
end