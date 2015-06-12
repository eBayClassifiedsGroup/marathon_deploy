require 'test_helper'

class EnvironmentTest < Minitest::Test

  
  def test_production_env_name
    environment_name = "PRODUCTION"
    environment = MarathonDeploy::Environment.new(environment_name)
    assert(environment.is_production?, "Environment #{environment_name} should be identified as production")
  end
end
