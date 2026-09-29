source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby file: '.ruby-version'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.1.4'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.0'
# Use Puma as the app server
gem 'puma'
# The original asset pipeline for Rails
gem 'sprockets-rails'
# Use Dart Sass for stylesheets
gem 'dartsass-sprockets'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Deploy this application anywhere as a Docker container
gem 'kamal', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma
gem 'thruster', require: false

gem 'haml'
gem 'bootstrap'
gem 'jquery-rails'
gem 'devise'
gem 'kaminari'
gem 'rexml'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

gem 'typhoeus'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'selenium-webdriver'
  # Read and write Excel workbooks for the religious centers data cleanup
  gem 'roo', require: false
  gem 'caxlsx', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]
