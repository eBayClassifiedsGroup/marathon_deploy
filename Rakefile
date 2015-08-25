require "bundler/gem_tasks"
require 'rake/testtask'

repo_path = `git rev-parse --show-toplevel`
project_name = `basename #{repo_path}`.strip


gemspec_file = FileList["#{project_name}.gemspec"].first
spec = eval(File.read(gemspec_file), binding, gemspec_file)

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/*_test.rb"
end

desc "Tag the repo as v#{spec.version} and push the code and tag."
task :tag do 
  sh "git tag -a -m 'Version #{spec.version}' v#{spec.version}"
end

desc "Push commits to origin/ecg repos"
task :push do 
  sh "git push --tags origin #{`git rev-parse --abbrev-ref HEAD`}"
  sh "git push --follow-tags origin #{`git rev-parse --abbrev-ref HEAD`}"
end

desc "Tag and push code to ecg and origin remote branches."
task :publish => [:tag, :push]

task :default => :test
