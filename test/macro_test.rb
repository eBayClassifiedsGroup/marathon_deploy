require 'test_helper'

class MacroTest < Minitest::Test

  def setup
    $LOG = Logger.new(STDOUT)
    $LOG.level = Logger::INFO
    @yml = File.expand_path('../fixtures/macros.yml',__FILE__)
    @docker_image_name = 'ubuntu'
    @docker_image_version = '14.04'
    @release_version = "TEST_VERSION_#{Time.now.utc.iso8601}"
    ENV['DOCKER_IMAGE_NAME'] = @docker_image_name
    ENV['DOCKER_IMAGE_VERSION'] = @docker_image_version
    ENV['RELEASE_VERSION'] = @release_version
  end

  def test_macro_processing
   result = YAML.load(MarathonDeploy::Macro.process_macros(@yml))
   assert_equal("#{@docker_image_name}:#{@docker_image_version}",result['container']['docker']['image'])
   assert_equal("#{@release_version}",result['env']['RELEASE_VERSION'])
  end
end
