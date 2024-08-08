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
