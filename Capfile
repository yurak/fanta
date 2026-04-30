require 'yaml'
app_yml = File.join(__dir__, 'config', 'application.yml')
YAML.load(File.read(app_yml)).each { |k, v| ENV[k.to_s] ||= v.to_s } if File.exist?(app_yml)

require 'capistrano/setup'
# Include default deployment tasks
require 'capistrano/deploy'
require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git
require 'capistrano/bundler'
require 'capistrano/rails'
require 'capistrano/passenger'
require 'capistrano/rvm'
require 'capistrano/yarn'
require 'whenever/capistrano'

set :rvm_type, :user
set :rvm_ruby_version, 'ruby-3.2.2'

require 'appsignal/capistrano'
