source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

gem 'rails', '~> 5.2.3'
gem 'sqlite3'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'bootstrap', '~> 4.0.0'
gem 'jquery-rails', '~> 4.3.1'
gem "haml-rails", "~> 2.0"
gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'

gem 'rubocop', require: false
gem 'devise'
gem 'devise-bootstrap-views', '~> 1.0'
gem 'bootsnap', '>= 1.1.0', require: false

gem 'rb-readline'

gem 'rails-i18n', '~> 5.1'
gem 'rest-client'
gem 'mini_racer'

gem 'chartkick'

group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.8'
end

group :development do
  gem "capistrano", "~> 3.10", require: false
  gem "capistrano-rails", "~> 1.4", require: false
  gem 'capistrano-passenger', '~> 0.2.0'
  gem 'capistrano-rvm'

  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
end

gem 'dotenv-rails', groups: [:development, :test]

group :test do
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
