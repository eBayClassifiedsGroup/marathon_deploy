require 'test_helper'

class ApplicationTest < Minitest::Test
  def setup
    $LOG = Logger.new(STDOUT)
    $LOG.level = Logger::INFO
    @release_version = "TEST_VERSION_#{Time.now.utc.iso8601}"
    ENV['RELEASE_VERSION'] = @release_version
    @json = File.expand_path('../fixtures/deploy.json',__FILE__)
    @yml = File.expand_path('../fixtures/deploy.yml',__FILE__)
  end
  
  def test_new_application_with_json
    application = MarathonDeploy::Application.new(:deployfile => @json)
    assert_instance_of(MarathonDeploy::Application,application)
    refute_empty(application.id)
    application.add_envs({ :MINITEST => "MINITEST_ENV_TEST" })
    assert_equal("MINITEST_ENV_TEST",application.env[:MINITEST])
  end
  
  def test_new_application_with_yaml
    application = MarathonDeploy::Application.new(:deployfile => @yml)
    assert_instance_of(MarathonDeploy::Application,application)
    refute_empty(application.id)
    assert_equal(@release_version,application.env[:RELEASE_VERSION])
  end
  
end
