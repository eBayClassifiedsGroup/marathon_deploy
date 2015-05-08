module YamlJson
  
require 'yaml'
require 'json'

  def self.yaml2json(filename)
    data = YAML::load_file(filename)
    JSON.parse(JSON.dump(data))
  end
  
  def self.json2yaml(filename)
    file = File.open(filename,'r')
    data = file.read   
    file.close
    json = JSON.parse(data)
    yml = YAML::dump(json)
  end
  
end